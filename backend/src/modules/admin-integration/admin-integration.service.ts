import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AgentEntity, AgentStatus } from '../../database/entities/agent.entity';
import { KycDocumentEntity, KycStatus } from '../../database/entities/kyc-document.entity';
import { PropertyEntity, PropertyStatus } from '../../database/entities/property.entity';
import { EarningEntity, EarningStatus } from '../../database/entities/earning.entity';
import { PaymentEntity, PaymentStatus } from '../../database/entities/payment.entity';
import { AgentWebSocketGateway } from '../websocket/agent-websocket.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';

@Injectable()
export class AdminIntegrationService {
  private readonly logger = new Logger(AdminIntegrationService.name);

  constructor(
    @InjectRepository(AgentEntity)
    private readonly agentRepository: Repository<AgentEntity>,
    @InjectRepository(KycDocumentEntity)
    private readonly kycRepository: Repository<KycDocumentEntity>,
    @InjectRepository(PropertyEntity)
    private readonly propertyRepository: Repository<PropertyEntity>,
    @InjectRepository(EarningEntity)
    private readonly earningRepository: Repository<EarningEntity>,
    @InjectRepository(PaymentEntity)
    private readonly paymentRepository: Repository<PaymentEntity>,
    @InjectRepository(AuditLogEntity)
    private readonly auditRepository: Repository<AuditLogEntity>,
    private readonly wsGateway: AgentWebSocketGateway,
    private readonly notificationsService: NotificationsService,
  ) {}

  async getAllAgents(status?: AgentStatus) {
    const whereCondition = status ? { status } : {};
    const agents = await this.agentRepository.find({
      where: whereCondition,
      relations: ['profile', 'kyc', 'bankAccount', 'user'],
      order: { createdAt: 'DESC' },
    });

    return {
      success: true,
      data: agents.map((a) => ({
        id: a.id,
        userId: a.userId,
        mobileNumber: a.user ? a.user.mobileNumber : null,
        status: a.status,
        rejectionReason: a.rejectionReason,
        fullName: a.profile ? a.profile.fullName : null,
        areaLocation: a.profile ? a.profile.areaLocation : null,
        workPlatform: a.profile ? a.profile.workPlatform : null,
        kycStatus: a.kyc ? a.kyc.status : 'NOT_SUBMITTED',
        bankAccountLast4: a.bankAccount ? a.bankAccount.accountLast4 : null,
        submittedAt: a.createdAt,
      })),
    };
  }

  async reviewKyc(agentId: string, approve: boolean, rejectionReason?: string) {
    const agent = await this.agentRepository.findOne({
      where: { id: agentId },
      relations: ['kyc'],
    });
    if (!agent || !agent.kyc) throw new NotFoundException('Agent KYC record not found');

    const kyc = agent.kyc;
    kyc.status = approve ? KycStatus.APPROVED : KycStatus.REJECTED;
    kyc.rejectionReason = approve ? null : rejectionReason || 'KYC document verification failed';
    kyc.reviewedAt = new Date();
    await this.kycRepository.save(kyc);

    // Notify agent via WebSocket and Push Notifications
    const eventName = 'kyc.status.updated';
    const notifTitle = approve ? 'KYC Approved' : 'KYC Rejected';
    const notifMsg = approve
      ? 'Your identity documents have been verified.'
      : `KYC Rejected: ${kyc.rejectionReason}`;

    this.wsGateway.emitToAgent(agentId, eventName, { status: kyc.status, rejectionReason: kyc.rejectionReason });
    await this.notificationsService.createNotification(agentId, notifTitle, notifMsg, approve ? 'KYC_APPROVED' : 'KYC_REJECTED');

    // Audit record
    await this.auditRepository.save({
      actorId: null,
      action: approve ? 'KYC_APPROVE' : 'KYC_REJECT',
      entityType: 'KYC_DOCUMENT',
      entityId: kyc.id,
      metadata: { agentId, rejectionReason: kyc.rejectionReason },
    });

    return { success: true, message: `KYC ${kyc.status}` };
  }

  async updateAgentStatus(agentId: string, status: AgentStatus, rejectionReason?: string) {
    const agent = await this.agentRepository.findOne({ where: { id: agentId } });
    if (!agent) throw new NotFoundException('Agent not found');

    agent.status = status;
    if (status === AgentStatus.APPROVED) {
      agent.approvedAt = new Date();
      agent.rejectionReason = null;
    } else if (status === AgentStatus.REJECTED || status === AgentStatus.SUSPENDED) {
      agent.rejectionReason = rejectionReason || `Agent account ${status.toLowerCase()}`;
    }

    await this.agentRepository.save(agent);

    // Real-time broadcast
    this.wsGateway.emitToAgent(agentId, 'agent.status.updated', {
      status: agent.status,
      rejectionReason: agent.rejectionReason,
    });

    await this.notificationsService.createNotification(
      agentId,
      `Account Status: ${status}`,
      `Your account status has been updated to ${status}.`,
      `AGENT_${status}`,
    );

    // Audit log
    await this.auditRepository.save({
      actorId: null,
      action: `AGENT_STATUS_${status}`,
      entityType: 'AGENT',
      entityId: agentId,
      metadata: { status, rejectionReason: agent.rejectionReason },
    });

    return { success: true, message: `Agent status updated to ${status}` };
  }

  async reviewProperty(propertyId: string, approve: boolean, rejectionReason?: string) {
    const property = await this.propertyRepository.findOne({ where: { id: propertyId } });
    if (!property) throw new NotFoundException('Property not found');

    property.status = approve ? PropertyStatus.APPROVED : PropertyStatus.REJECTED;
    property.rejectionReason = approve ? null : rejectionReason || 'Property details did not satisfy verification rules';
    property.reviewedAt = new Date();
    await this.propertyRepository.save(property);

    this.wsGateway.emitToAgent(property.agentId, 'property.status.updated', {
      propertyId: property.id,
      status: property.status,
      rejectionReason: property.rejectionReason,
    });

    await this.notificationsService.createNotification(
      property.agentId,
      approve ? 'Property Approved!' : 'Property Listing Rejected',
      approve ? `Your property "${property.title}" is now active.` : `Listing "${property.title}" rejected: ${property.rejectionReason}`,
      approve ? 'PROPERTY_APPROVED' : 'PROPERTY_REJECTED',
    );

    return { success: true, message: `Property status updated to ${property.status}` };
  }

  async createEarning(agentId: string, title: string, amount: number, propertyId?: string) {
    const agent = await this.agentRepository.findOne({ where: { id: agentId } });
    if (!agent) throw new NotFoundException('Agent not found');

    const earning = this.earningRepository.create({
      agentId,
      title,
      amount,
      propertyId,
      status: EarningStatus.PENDING,
      earnedDate: new Date(),
    });

    const savedEarning = await this.earningRepository.save(earning);

    await this.notificationsService.createNotification(
      agentId,
      'New Earning Added',
      `You earned ₹${amount.toLocaleString('en-IN')} for "${title}".`,
      'EARNING_CREATED',
    );

    return { success: true, data: savedEarning };
  }

  async recordPayment(agentId: string, amount: number, transactionId: string, paymentMethod: string, earningId?: string, paymentProofKey?: string) {
    const agent = await this.agentRepository.findOne({ where: { id: agentId } });
    if (!agent) throw new NotFoundException('Agent not found');

    const payment = this.paymentRepository.create({
      agentId,
      amount,
      transactionId,
      paymentMethod,
      paymentProofKey,
      earningId,
      status: PaymentStatus.COMPLETED,
      paidAt: new Date(),
    });

    const savedPayment = await this.paymentRepository.save(payment);

    if (earningId) {
      await this.earningRepository.update({ id: earningId }, { status: EarningStatus.PAID });
    }

    this.wsGateway.emitToAgent(agentId, 'payment.created', {
      paymentId: savedPayment.id,
      amount: savedPayment.amount,
      transactionId: savedPayment.transactionId,
    });

    await this.notificationsService.createNotification(
      agentId,
      'Payment Received!',
      `₹${amount.toLocaleString('en-IN')} has been transferred (Txn: ${transactionId}).`,
      'PAYMENT_RECORDED',
    );

    return { success: true, data: savedPayment };
  }
}
