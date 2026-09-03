import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EarningEntity, EarningStatus } from '../../database/entities/earning.entity';
import { PaymentEntity, PaymentStatus } from '../../database/entities/payment.entity';
import { AgentEntity } from '../../database/entities/agent.entity';

@Injectable()
export class EarningsService {
  private readonly logger = new Logger(EarningsService.name);

  constructor(
    @InjectRepository(EarningEntity)
    private readonly earningRepository: Repository<EarningEntity>,
    @InjectRepository(PaymentEntity)
    private readonly paymentRepository: Repository<PaymentEntity>,
    @InjectRepository(AgentEntity)
    private readonly agentRepository: Repository<AgentEntity>,
  ) {}

  async getEarningsSummary(userId: string) {
    const agent = await this.agentRepository.findOne({ where: { userId } });
    if (!agent) throw new NotFoundException('Agent not found');

    const earnings = await this.earningRepository.find({
      where: { agentId: agent.id },
      relations: ['property'],
      order: { earnedDate: 'DESC' },
    });

    const payments = await this.paymentRepository.find({
      where: { agentId: agent.id, status: PaymentStatus.COMPLETED },
      order: { paidAt: 'DESC' },
    });

    let totalEarnings = 0;
    let pendingEarnings = 0;
    let paidAmount = 0;
    let thisMonthEarnings = 0;

    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    const formattedList = earnings.map((e) => {
      const amt = Number(e.amount);
      totalEarnings += amt;
      if (e.status === EarningStatus.PENDING) {
        pendingEarnings += amt;
      } else if (e.status === EarningStatus.PAID) {
        paidAmount += amt;
      }

      const eDate = new Date(e.earnedDate);
      if (eDate.getMonth() === currentMonth && eDate.getFullYear() === currentYear) {
        thisMonthEarnings += amt;
      }

      return {
        id: e.id,
        title: e.title,
        amount: amt,
        status: e.status,
        earnedDate: e.earnedDate,
        propertyTitle: e.property ? e.property.title : null,
      };
    });

    // Check if there are any completed payments that were direct and not captured in earnings list
    const linkedEarningIds = new Set(earnings.map((e) => e.id));
    for (const p of payments) {
      if (!p.earningId || !linkedEarningIds.has(p.earningId)) {
        const pAmt = Number(p.amount);
        paidAmount += pAmt;
        totalEarnings += pAmt;
        const pDate = new Date(p.paidAt);
        if (pDate.getMonth() === currentMonth && pDate.getFullYear() === currentYear) {
          thisMonthEarnings += pAmt;
        }
        formattedList.push({
          id: p.id,
          title: `Direct Payout (Txn: ${p.transactionId})`,
          amount: pAmt,
          status: EarningStatus.PAID,
          earnedDate: p.paidAt,
          propertyTitle: null,
        });
      }
    }

    return {
      success: true,
      data: {
        summary: {
          totalEarnings,
          pendingEarnings,
          paidAmount,
          thisMonthEarnings,
        },
        earnings: formattedList,
      },
    };
  }
}
