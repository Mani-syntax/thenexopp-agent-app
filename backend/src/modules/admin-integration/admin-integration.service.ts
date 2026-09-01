import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, LessThanOrEqual, MoreThanOrEqual } from 'typeorm';
import { AgentEntity, AgentStatus } from '../../database/entities/agent.entity';
import { KycDocumentEntity, KycStatus } from '../../database/entities/kyc-document.entity';
import { PropertyEntity, PropertyStatus } from '../../database/entities/property.entity';
import { PropertyImageEntity } from '../../database/entities/property-image.entity';
import { EarningEntity, EarningStatus } from '../../database/entities/earning.entity';
import { PaymentEntity, PaymentStatus } from '../../database/entities/payment.entity';
import { AgentWebSocketGateway } from '../websocket/agent-websocket.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';
import { UploadsService, BucketType } from '../uploads/uploads.service';

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
    @InjectRepository(PropertyImageEntity)
    private readonly imageRepository: Repository<PropertyImageEntity>,
    @InjectRepository(EarningEntity)
    private readonly earningRepository: Repository<EarningEntity>,
    @InjectRepository(PaymentEntity)
    private readonly paymentRepository: Repository<PaymentEntity>,
    @InjectRepository(AuditLogEntity)
    private readonly auditRepository: Repository<AuditLogEntity>,
    private readonly wsGateway: AgentWebSocketGateway,
    private readonly notificationsService: NotificationsService,
    private readonly uploadsService: UploadsService,
  ) {}

  async getAllAgents(status?: AgentStatus, search?: string) {
    const whereCondition: any = status ? { status } : {};
    const agents = await this.agentRepository.find({
      where: whereCondition,
      relations: ['profile', 'kyc', 'bankAccount', 'user', 'properties', 'payments', 'earnings'],
      order: { createdAt: 'DESC' },
    });

    let filtered = agents;
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      filtered = agents.filter((a) => {
        const name = (a.profile?.fullName || '').toLowerCase();
        const mobile = (a.user?.mobileNumber || '');
        const area = (a.profile?.areaLocation || '').toLowerCase();
        return name.includes(q) || mobile.includes(q) || area.includes(q);
      });
    }

    return {
      success: true,
      data: filtered.map((a) => {
        const props = a.properties || [];
        const payments = a.payments || [];
        const earnings = a.earnings || [];

        const totalListings = props.length;
        const acceptedListings = props.filter((p) => p.status === PropertyStatus.APPROVED).length;
        const rejectedListings = props.filter((p) => p.status === PropertyStatus.REJECTED).length;
        const pendingListings = props.filter((p) => p.status === PropertyStatus.SUBMITTED || p.status === PropertyStatus.UNDER_REVIEW).length;

        const totalPaid = payments
          .filter((p) => p.status === PaymentStatus.COMPLETED)
          .reduce((sum, p) => sum + Number(p.amount || 0), 0);

        const pendingEarnings = earnings
          .filter((e) => e.status === EarningStatus.PENDING)
          .reduce((sum, e) => sum + Number(e.amount || 0), 0);

        return {
          id: a.id,
          userId: a.userId,
          mobileNumber: a.user ? a.user.mobileNumber : null,
          status: a.status,
          rejectionReason: a.rejectionReason,
          fullName: a.profile ? a.profile.fullName : null,
          profilePhotoUrl: a.profile ? a.profile.profilePhotoUrl : null,
          areaLocation: a.profile ? a.profile.areaLocation : null,
          workPlatform: a.profile ? a.profile.workPlatform : null,
          kycStatus: a.kyc ? a.kyc.status : 'NOT_SUBMITTED',
          bankAccountLast4: a.bankAccount ? a.bankAccount.accountLast4 : null,
          submittedAt: a.createdAt,
          totalListings,
          acceptedListings,
          rejectedListings,
          pendingListings,
          totalPaid,
          pendingEarnings,
        };
      }),
    };
  }

  async getAllProperties(status?: PropertyStatus, startDate?: string, endDate?: string, agentId?: string, search?: string) {
    const query = this.propertyRepository
      .createQueryBuilder('property')
      .leftJoinAndSelect('property.images', 'images')
      .leftJoinAndSelect('property.agent', 'agent')
      .leftJoinAndSelect('agent.profile', 'profile')
      .leftJoinAndSelect('agent.user', 'user')
      .orderBy('property.createdAt', 'DESC');

    if (status) {
      query.andWhere('property.status = :status', { status });
    }

    if (agentId) {
      query.andWhere('property.agentId = :agentId', { agentId });
    }

    if (startDate) {
      const start = new Date(startDate);
      query.andWhere('property.createdAt >= :start', { start });
    }

    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      query.andWhere('property.createdAt <= :end', { end });
    }

    if (search && search.trim()) {
      const q = `%${search.trim()}%`;
      query.andWhere(
        '(property.title ILIKE :q OR property.location ILIKE :q OR profile.fullName ILIKE :q OR user.mobileNumber ILIKE :q)',
        { q },
      );
    }

    const properties = await query.getMany();

    const results = await Promise.all(
      properties.map(async (prop) => {
        const imagesWithUrls = await Promise.all(
          (prop.images || []).map(async (img) => {
            let url = null;
            try {
              url = await this.uploadsService.getPresignedReadUrl(BucketType.PROPERTY, img.imageKey);
            } catch (_) {}
            return {
              id: img.id,
              imageKey: img.imageKey,
              isPrimary: img.isPrimary,
              displayOrder: img.displayOrder,
              url,
            };
          }),
        );

        return {
          id: prop.id,
          agentId: prop.agentId,
          agent: {
            id: prop.agent ? prop.agent.id : prop.agentId,
            fullName: prop.agent?.profile?.fullName || 'Agent Partner',
            mobileNumber: prop.agent?.user?.mobileNumber || '',
            areaLocation: prop.agent?.profile?.areaLocation || '',
            workPlatform: prop.agent?.profile?.workPlatform || '',
          },
          title: prop.title,
          description: prop.description,
          price: Number(prop.price),
          category: prop.category,
          specifications: prop.specifications || {},
          location: prop.location,
          status: prop.status,
          rejectionReason: prop.rejectionReason,
          submittedAt: prop.submittedAt,
          reviewedAt: prop.reviewedAt,
          createdAt: prop.createdAt,
          images: imagesWithUrls,
        };
      }),
    );

    return {
      success: true,
      data: results,
    };
  }

  async getPaymentRecords(startDate?: string, endDate?: string, agentId?: string, search?: string) {
    const query = this.paymentRepository
      .createQueryBuilder('payment')
      .leftJoinAndSelect('payment.agent', 'agent')
      .leftJoinAndSelect('agent.profile', 'profile')
      .leftJoinAndSelect('agent.user', 'user')
      .leftJoinAndSelect('payment.earning', 'earning')
      .orderBy('payment.paidAt', 'DESC');

    if (agentId) {
      query.andWhere('payment.agentId = :agentId', { agentId });
    }

    if (startDate) {
      const start = new Date(startDate);
      query.andWhere('payment.paidAt >= :start', { start });
    }

    if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      query.andWhere('payment.paidAt <= :end', { end });
    }

    if (search && search.trim()) {
      const q = `%${search.trim()}%`;
      query.andWhere(
        '(payment.transactionId ILIKE :q OR profile.fullName ILIKE :q OR user.mobileNumber ILIKE :q OR earning.title ILIKE :q)',
        { q },
      );
    }

    const payments = await query.getMany();

    // Calculate aggregated analytics across all recorded payments
    const allPayments = await this.paymentRepository.find({
      where: { status: PaymentStatus.COMPLETED },
    });

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const totalSpent = allPayments.reduce((acc, p) => acc + Number(p.amount || 0), 0);
    const todaySpent = allPayments
      .filter((p) => new Date(p.paidAt) >= startOfToday)
      .reduce((acc, p) => acc + Number(p.amount || 0), 0);
    const thisWeekSpent = allPayments
      .filter((p) => new Date(p.paidAt) >= sevenDaysAgo)
      .reduce((acc, p) => acc + Number(p.amount || 0), 0);
    const thisMonthSpent = allPayments
      .filter((p) => new Date(p.paidAt) >= startOfMonth)
      .reduce((acc, p) => acc + Number(p.amount || 0), 0);

    const data = payments.map((p) => ({
      id: p.id,
      agentId: p.agentId,
      agent: {
        id: p.agent ? p.agent.id : p.agentId,
        fullName: p.agent?.profile?.fullName || 'Agent Partner',
        mobileNumber: p.agent?.user?.mobileNumber || '',
      },
      earningId: p.earningId,
      earningTitle: p.earning ? p.earning.title : null,
      amount: Number(p.amount),
      transactionId: p.transactionId,
      paymentMethod: p.paymentMethod,
      status: p.status,
      paymentProofKey: p.paymentProofKey,
      paidAt: p.paidAt,
      createdAt: p.createdAt,
    }));

    return {
      success: true,
      analytics: {
        totalSpent,
        todaySpent,
        thisWeekSpent,
        thisMonthSpent,
        totalTransactions: allPayments.length,
      },
      data,
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
