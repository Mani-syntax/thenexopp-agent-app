import { Controller, Post, Body, UseGuards, Get, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UploadsService, BucketType } from './uploads.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

class PresignedUrlDto {
  bucketType: BucketType;
  filename: string;
  mimeType: string;
}

@ApiTags('Uploads')
@Controller('uploads')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('presigned-url')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Generate presigned S3 upload URL for private bucket storage' })
  async getPresignedUploadUrl(@Body() body: PresignedUrlDto) {
    return this.uploadsService.getPresignedUploadUrl(body.bucketType, body.filename, body.mimeType);
  }

  @Get('secure-view-url')
  @ApiOperation({ summary: 'Generate presigned read URL for private KYC / payment proof files' })
  async getPresignedReadUrl(@Query('bucket') bucket: BucketType, @Query('key') key: string) {
    const url = await this.uploadsService.getPresignedReadUrl(bucket, key);
    return { success: true, data: { viewUrl: url } };
  }
}
