import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches, IsOptional } from 'class-validator';

export class SubmitBankDetailsDto {
  @ApiProperty({ example: '918234567890' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{9,18}$/, { message: 'Bank account number must be between 9 and 18 digits' })
  accountNumber: string;

  @ApiProperty({ example: '918234567890' })
  @IsNotEmpty()
  @IsString()
  confirmAccountNumber: string;

  @ApiProperty({ example: 'SBIN0001234' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^[A-Z]{4}0[A-Z0-9]{6}$/, { message: 'IFSC Code must be valid (e.g. SBIN0001234)' })
  ifscCode: string;

  @ApiProperty({ example: 'rajesh@upi' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^[\w.-]+@[\w.-]+$/, { message: 'UPI ID format must be valid (e.g. username@bank)' })
  upiId: string;

  @ApiProperty({ example: '9876543210', required: false })
  @IsOptional()
  @IsString()
  phonepeNumber?: string;
}
