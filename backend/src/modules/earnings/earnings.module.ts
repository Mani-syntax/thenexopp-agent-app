import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EarningEntity } from '../../database/entities/earning.entity';
import { AgentEntity } from '../../database/entities/agent.entity';
import { EarningsController } from './earnings.controller';
import { EarningsService } from './earnings.service';

@Module({
  imports: [TypeOrmModule.forFeature([EarningEntity, AgentEntity])],
  controllers: [EarningsController],
  providers: [EarningsService],
  exports: [EarningsService],
})
export class EarningsModule {}
