import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EarningEntity, EarningStatus } from '../../database/entities/earning.entity';
import { AgentEntity } from '../../database/entities/agent.entity';

@Injectable()
export class EarningsService {
  private readonly logger = new Logger(EarningsService.name);

  constructor(
    @InjectRepository(EarningEntity)
    private readonly earningRepository: Repository<EarningEntity>,
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
