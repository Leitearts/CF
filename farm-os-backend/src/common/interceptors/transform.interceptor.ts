import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: true;
  data: T;
  error: null;
  meta?: Record<string, unknown>;
}

/**
 * Wraps every successful controller response in a consistent envelope so
 * mobile clients never need to special-case response shapes per endpoint.
 * Errors are shaped separately by HttpExceptionFilter using the same envelope.
 */
@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((payload) => {
        // Controllers may return { data, meta } to attach pagination/meta info.
        if (
          payload &&
          typeof payload === 'object' &&
          'data' in payload &&
          'meta' in payload
        ) {
          const { data, meta } = payload as { data: T; meta: Record<string, unknown> };
          return { success: true, data, error: null, meta };
        }
        return { success: true, data: payload, error: null };
      }),
    );
  }
}
