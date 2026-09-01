import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminIntegrationService } from './admin-integration.service';
import { AgentStatus } from '../../database/entities/agent.entity';
import { PropertyStatus } from '../../database/entities/property.entity';
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
  @ApiOperation({ summary: 'List all agents with performance metrics' })
  @ApiQuery({ name: 'status', enum: AgentStatus, required: false })
  @ApiQuery({ name: 'search', required: false })
  async getAllAgents(
    @Query('status') status?: AgentStatus,
    @Query('search') search?: string,
  ) {
    return this.adminService.getAllAgents(status, search);
  }

  @Get('properties')
  @ApiOperation({ summary: 'List all properties day-wise with agent details and pictures' })
  @ApiQuery({ name: 'status', enum: PropertyStatus, required: false })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  @ApiQuery({ name: 'agentId', required: false })
  @ApiQuery({ name: 'search', required: false })
  async getAllProperties(
    @Query('status') status?: PropertyStatus,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('agentId') agentId?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.getAllProperties(status, startDate, endDate, agentId, search);
  }

  @Get('payments')
  @ApiOperation({ summary: 'List all payment records and financial analytics' })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  @ApiQuery({ name: 'agentId', required: false })
  @ApiQuery({ name: 'search', required: false })
  async getPaymentRecords(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('agentId') agentId?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.getPaymentRecords(startDate, endDate, agentId, search);
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
