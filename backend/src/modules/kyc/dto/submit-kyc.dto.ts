import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class SubmitKycDto {
  @ApiProperty({ example: '123456789012', description: '12-digit Aadhaar Number' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\d{12}$/, { message: 'Aadhaar must be exactly 12 digits' })
  aadhaarNumber: string;

  @ApiProperty({ example: 'ABCDE1234F', description: '10-character PAN Number' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/, { message: 'PAN must be valid 10-character alphanumeric string (e.g. ABCDE1234F)' })
  panNumber: string;

  @ApiProperty({ example: 'kyc-aadhaar-key-123.jpg' })
  @IsNotEmpty()
  @IsString()
  aadhaarDocKey: string;

  @ApiProperty({ example: 'kyc-pan-key-123.jpg' })
  @IsNotEmpty()
  @IsString()
  panDocKey: string;
}
