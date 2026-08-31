export type AgentStatus =
  | 'NEW'
  | 'PROFILE_INCOMPLETE'
  | 'KYC_INCOMPLETE'
  | 'BANK_DETAILS_INCOMPLETE'
  | 'PENDING_APPROVAL'
  | 'APPROVED'
  | 'REJECTED'
  | 'SUSPENDED';

export type KycStatus = 'NOT_SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED';
export type PropertyStatus = 'DRAFT' | 'SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED';
export type EarningStatus = 'PENDING' | 'PAID';
export type PaymentStatus = 'IN_TRANSIT' | 'COMPLETED' | 'FAILED';

export interface AgentSummary {
  id: string;
  userId: string;
  mobileNumber: string | null;
  status: AgentStatus;
  rejectionReason: string | null;
  fullName: string | null;
  areaLocation: string | null;
  workPlatform: string | null;
  kycStatus: KycStatus;
  bankAccountLast4: string | null;
  submittedAt: string;
}

export interface PropertyListing {
  id: string;
  agentId: string;
  title: string;
  description: string;
  price: number;
  category: string;
  location: string;
  status: PropertyStatus;
  rejectionReason?: string;
  submittedAt: string;
}

export interface EarningRecord {
  id: string;
  agentId: string;
  title: string;
  amount: number;
  status: EarningStatus;
  earnedDate: string;
}

export interface PaymentRecord {
  id: string;
  agentId: string;
  amount: number;
  transactionId: string;
  paymentMethod: string;
  status: PaymentStatus;
  paidAt: string;
}
