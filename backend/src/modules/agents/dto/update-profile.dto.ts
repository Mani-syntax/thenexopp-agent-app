import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsInt, Min, Max, IsIn, IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @ApiProperty({ example: 'Rajesh Kumar' })
  @IsNotEmpty()
  @IsString()
  fullName: string;

  @ApiProperty({ example: 'Koramangala, Bengaluru' })
  @IsNotEmpty()
  @IsString()
  areaLocation: string;

  @ApiProperty({ example: 28 })
  @IsNotEmpty()
  @IsInt()
  @Min(18)
  @Max(80)
  age: number;

  @ApiProperty({ example: 'Male' })
  @IsNotEmpty()
  @IsString()
  gender: string;

  @ApiProperty({ example: 'Real Estate Agent', description: 'Current occupation or work (optional)', required: false })
  @IsOptional()
  @IsString()
  workPlatform?: string;

  @ApiProperty({ example: 'https://minio.thenexopp.com/profile.jpg', required: false })
  @IsOptional()
  @IsString()
  profilePhotoUrl?: string;
}
