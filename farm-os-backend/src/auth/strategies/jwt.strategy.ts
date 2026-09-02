import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

export interface JwtPayload {
  sub: string; // user id
  email?: string;
  phone?: string;
}

export interface AuthenticatedUser {
  id: string;
  email?: string;
  phone?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_ACCESS_SECRET ?? 'change-me-access-secret',
    });
  }

  // Whatever is returned here becomes `request.user` (see CurrentUser decorator).
  validate(payload: JwtPayload): AuthenticatedUser {
    return { id: payload.sub, email: payload.email, phone: payload.phone };
  }
}
