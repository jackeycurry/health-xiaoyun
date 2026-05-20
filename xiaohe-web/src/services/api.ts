import axios, { AxiosError } from "axios";

const TOKEN_KEY = "xiaohe.token";

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null) {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

export const api = axios.create({
  baseURL: "/api",
  timeout: 15000,
});

api.interceptors.request.use((cfg) => {
  const t = getToken();
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

api.interceptors.response.use(
  (r) => r,
  (err: AxiosError<any>) => {
    if (err.response?.status === 401) {
      setToken(null);
      // soft redirect — let router pick it up
      if (location.pathname !== "/login") location.assign("/login");
    }
    return Promise.reject(err);
  }
);

export interface UserResponse {
  id: string;
  phone: string;
  nickname: string;
  avatar_url: string | null;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
}

export const auth = {
  async login(phone: string, password: string): Promise<TokenResponse> {
    const { data } = await api.post<TokenResponse>("/auth/login", { phone, password });
    return data;
  },
  async register(phone: string, password: string): Promise<UserResponse> {
    const { data } = await api.post<UserResponse>("/auth/register", { phone, password });
    return data;
  },
  async me(): Promise<UserResponse> {
    const { data } = await api.get<UserResponse>("/auth/me");
    return data;
  },
};

// ─── conversations ─────────────────────────────────────────
export interface ConversationItem {
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
}
export interface MessageItem {
  id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
}
export interface ConversationDetail {
  id: string;
  title: string;
  messages: MessageItem[];
  created_at: string;
}

export const conv = {
  async welcomeSuggestions(): Promise<string[]> {
    const { data } = await api.get<{ suggestions: string[] }>("/consult/welcome-suggestions");
    return data.suggestions ?? [];
  },
  async list(): Promise<ConversationItem[]> {
    const { data } = await api.get<{ conversations: ConversationItem[] }>("/consult/conversations");
    return data.conversations;
  },
  async get(id: string): Promise<ConversationDetail> {
    const { data } = await api.get<ConversationDetail>(`/consult/conversations/${id}`);
    return data;
  },
  async remove(id: string): Promise<void> {
    await api.delete(`/consult/conversations/${id}`);
  },
  async regenTitle(id: string): Promise<{ id: string; title: string }> {
    const { data } = await api.post<{ id: string; title: string }>(
      `/consult/conversations/${id}/regenerate-title`
    );
    return data;
  },
};

// ─── user profile + memories ───────────────────────────────
export interface ProfileBase {
  gender: string | null;
  age: number | null;
  height: number | null;
  weight: number | null;
  health_summary: string | null;
  risk_tags: string[] | null;
}
export interface MemoryRow {
  id: string;
  category: string;
  fact: string;
  importance: number;
  created_at: string;
}
export interface ProfileFull {
  profile: ProfileBase | null;
  memories: MemoryRow[];
}
export interface ProfileUpdate {
  gender?: string;
  age?: number;
  height?: number;
  weight?: number;
}

export const profile = {
  async get(): Promise<ProfileFull> {
    const { data } = await api.get<ProfileFull>("/user/profile");
    return data;
  },
  async update(patch: ProfileUpdate): Promise<ProfileBase> {
    const { data } = await api.put<ProfileBase>("/user/profile", patch);
    return data;
  },
  async deleteMemory(id: string): Promise<void> {
    await api.delete(`/user/memories/${id}`);
  },
};

// ─── health records ────────────────────────────────────────
export type HealthRecordType =
  | "blood_pressure" | "blood_sugar" | "weight" | "temperature" | "heart_rate";

export interface HealthRecord {
  id: string;
  user_id: string;
  type: HealthRecordType;
  value: Record<string, any>;
  recorded_at: string;
  note: string | null;
  created_at: string;
}

export interface HealthRecordCreate {
  type: HealthRecordType;
  value: Record<string, any>;
  recorded_at: string;
  note?: string;
}

export interface LatestRecords {
  blood_pressure: Record<string, any> | null;
  blood_sugar: Record<string, any> | null;
  weight: Record<string, any> | null;
  temperature: Record<string, any> | null;
  heart_rate: Record<string, any> | null;
}

export const health = {
  async list(opts: { type?: HealthRecordType; limit?: number; offset?: number } = {}): Promise<HealthRecord[]> {
    const params: Record<string, any> = {};
    if (opts.type) params.record_type = opts.type;
    if (opts.limit !== undefined) params.limit = opts.limit;
    if (opts.offset !== undefined) params.offset = opts.offset;
    const { data } = await api.get<HealthRecord[]>("/health/records", { params });
    return data;
  },
  async latest(): Promise<LatestRecords> {
    const { data } = await api.get<LatestRecords>("/health/records/latest");
    return data;
  },
  async create(rec: HealthRecordCreate): Promise<HealthRecord> {
    const { data } = await api.post<HealthRecord>("/health/records", rec);
    return data;
  },
  async remove(id: string): Promise<void> {
    await api.delete(`/health/records/${id}`);
  },
};
