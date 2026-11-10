const request = require('supertest');

// Mock mongoose and redis to allow tests without live databases
jest.mock('../src/config/db', () => jest.fn().mockResolvedValue({}));
jest.mock('../src/config/redis', () => ({
  get: jest.fn().mockResolvedValue(null),
  set: jest.fn().mockResolvedValue('OK'),
  del: jest.fn().mockResolvedValue(1),
  isLive: jest.fn().mockReturnValue(false)
}));

jest.mock('../src/models/User', () => {
  const mockUser = {
    _id: 'user123',
    email: 'test@example.com',
    name: 'Test User',
    role: 'user',
    isActive: true,
    lastLoginAt: null,
    googleId: null,
    comparePassword: jest.fn().mockResolvedValue(true),
    save: jest.fn().mockResolvedValue(true)
  };

  const UserModel = jest.fn(() => mockUser);
  UserModel.findOne = jest.fn().mockResolvedValue(null);
  UserModel.findById = jest.fn().mockResolvedValue(mockUser);
  UserModel.create = jest.fn().mockResolvedValue(mockUser);
  UserModel.hashPassword = jest.fn().mockResolvedValue('hashed_password');
  return UserModel;
});

jest.mock('../src/models/Device', () => {
  const DeviceModel = jest.fn();
  DeviceModel.findOneAndUpdate = jest.fn().mockResolvedValue({ deviceId: 'desktop_01', name: 'Test PC' });
  DeviceModel.findOne = jest.fn().mockResolvedValue(null);
  return DeviceModel;
});

jest.mock('../src/models/Settings', () => {
  const SettingsModel = jest.fn();
  SettingsModel.create = jest.fn().mockResolvedValue({});
  SettingsModel.findOne = jest.fn().mockResolvedValue({});
  return SettingsModel;
});

jest.mock('../src/models/AuditLog', () => ({
  create: jest.fn().mockResolvedValue({})
}));

describe('Authentication API', () => {
  let app;

  beforeAll(() => {
    // Import app after mocks are set up
    const { app: expressApp } = require('../src/server');
    app = expressApp;
  });

  describe('POST /api/auth/register', () => {
    it('should return 400 when required fields are missing', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({ email: 'test@test.com' })
        .expect('Content-Type', /json/)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Missing required field');
    });

    it('should register a new user successfully', async () => {
      const User = require('../src/models/User');
      User.findOne.mockResolvedValueOnce(null); // No existing user

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'newuser@example.com',
          password: 'SecureP@ss123',
          name: 'New User',
          deviceId: 'desktop_01',
          platform: 'windows',
          deviceType: 'desktop'
        })
        .expect('Content-Type', /json/)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('tokens');
      expect(response.body.data.tokens).toHaveProperty('accessToken');
      expect(response.body.data.tokens).toHaveProperty('refreshToken');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should return 400 when password is missing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({ email: 'test@example.com' })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should login successfully with valid credentials', async () => {
      const User = require('../src/models/User');
      User.findOne.mockResolvedValueOnce({
        _id: 'user123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        isActive: true,
        lastLoginAt: null,
        comparePassword: jest.fn().mockResolvedValue(true),
        save: jest.fn().mockResolvedValue(true)
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Password123',
          deviceId: 'desktop_01',
          platform: 'windows',
          deviceType: 'desktop'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.tokens).toHaveProperty('accessToken');
    });
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('healthy');
      expect(response.body).toHaveProperty('uptime');
    });
  });
});
