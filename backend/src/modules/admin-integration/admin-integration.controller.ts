import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminIntegrationService } from './admin-integration.service';
import { AgentStatus } from '../../database/entities/agent.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

class ReviewKycDto {
  approve: boolean;
  rejectionReason?: string;
}

class UpdateAgentStatusDto {
  status: AgentStatus;
  rejectionReason?: string;
}

class ReviewPropertyDto {
  approve: boolean;
  rejectionReason?: string;
}

class CreateEarningDto {
  agentId: string;
  title: string;
  amount: number;
  propertyId?: string;
}

class RecordPaymentDto {
  agentId: string;
  amount: number;
  transactionId: string;
  paymentMethod: string;
  earningId?: string;
  paymentProofKey?: string;
}

@ApiTags('Admin Integration')
@Controller('admin')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AdminIntegrationController {
  constructor(private readonly adminService: AdminIntegrationService) {}

  @Get('agents')
  @ApiOperation({ summary: 'List all agents for Admin inspection' })
  @ApiQuery({ name: 'status', enum: AgentStatus, required: false })
  async getAllAgents(@Query('status') status?: AgentStatus) {
    return this.adminService.getAllAgents(status);
  }

  @Put('agents/:id/kyc')
  @ApiOperation({ summary: 'Approve or Reject agent KYC' })
  async reviewKyc(@Param('id') agentId: string, @Body() body: ReviewKycDto) {
    return this.adminService.reviewKyc(agentId, body.approve, body.rejectionReason);
  }

  @Put('agents/:id/status')
  @ApiOperation({ summary: 'Approve, Reject, or Suspend Agent Account' })
  async updateAgentStatus(@Param('id') agentId: string, @Body() body: UpdateAgentStatusDto) {
    return this.adminService.updateAgentStatus(agentId, body.status, body.rejectionReason);
  }

  @Put('properties/:id/review')
  @ApiOperation({ summary: 'Approve or Reject property listing' })
  async reviewProperty(@Param('id') propertyId: string, @Body() body: ReviewPropertyDto) {
    return this.adminService.reviewProperty(propertyId, body.approve, body.rejectionReason);
  }

  @Post('earnings')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create earning record for agent' })
  async createEarning(@Body() body: CreateEarningDto) {
    return this.adminService.createEarning(body.agentId, body.title, body.amount, body.propertyId);
  }

  @Post('payments')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Record payment transaction and payment proof' })
  async recordPayment(@Body() body: RecordPaymentDto) {
    return this.adminService.recordPayment(
      body.agentId,
      body.amount,
      body.transactionId,
      body.paymentMethod,
      body.earningId,
      body.paymentProofKey,
    );
  }
}
