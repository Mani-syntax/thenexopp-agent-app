import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AgentEntity } from '../../database/entities/agent.entity';
import { KycDocumentEntity } from '../../database/entities/kyc-document.entity';
import { PropertyEntity } from '../../database/entities/property.entity';
import { PropertyImageEntity } from '../../database/entities/property-image.entity';
import { EarningEntity } from '../../database/entities/earning.entity';
import { PaymentEntity } from '../../database/entities/payment.entity';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';
import { AdminIntegrationController } from './admin-integration.controller';
import { AdminIntegrationService } from './admin-integration.service';
import { WebsocketModule } from '../websocket/websocket.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UploadsModule } from '../uploads/uploads.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      AgentEntity,
      KycDocumentEntity,
      PropertyEntity,
      PropertyImageEntity,
      EarningEntity,
      PaymentEntity,
      AuditLogEntity,
    ]),
    WebsocketModule,
    NotificationsModule,
    UploadsModule,
  ],
  controllers: [AdminIntegrationController],
  providers: [AdminIntegrationService],
  exports: [AdminIntegrationService],
})
export class AdminIntegrationModule {}
