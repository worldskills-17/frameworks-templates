import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getRoot(): string {
    return this.appService.welcomeHtml();
  }

  @Get('test')
  getTest(): { msg: string } {
    return { msg: 'This is CORS-enabled for all origins!' };
  }
}
