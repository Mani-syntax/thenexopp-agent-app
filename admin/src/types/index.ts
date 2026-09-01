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
  totalListings?: number;
  acceptedListings?: number;
  rejectedListings?: number;
  pendingListings?: number;
  totalPaid?: number;
  pendingEarnings?: number;
}

export interface PropertyImage {
  id: string;
  imageKey: string;
  isPrimary: boolean;
  displayOrder: number;
  url: string | null;
}

export interface PropertyAgent {
  id: string;
  fullName: string;
  mobileNumber: string;
  areaLocation?: string;
  workPlatform?: string;
}

export interface PropertyListing {
  id: string;
  agentId: string;
  agent: PropertyAgent;
  title: string;
  description: string;
  price: number;
  category: string;
  specifications: Record<string, any>;
  location: string;
  status: PropertyStatus;
  rejectionReason?: string;
  submittedAt: string;
  reviewedAt?: string;
  createdAt: string;
  images: PropertyImage[];
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
  agent: {
    id: string;
    fullName: string;
    mobileNumber: string;
  };
  earningId?: string;
  earningTitle?: string | null;
  amount: number;
  transactionId: string;
  paymentMethod: string;
  status: PaymentStatus;
  paymentProofKey?: string;
  paidAt: string;
  createdAt: string;
}

export interface PaymentAnalytics {
  totalSpent: number;
  todaySpent: number;
  thisWeekSpent: number;
  thisMonthSpent: number;
  totalTransactions: number;
}
