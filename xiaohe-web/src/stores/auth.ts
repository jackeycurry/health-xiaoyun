import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { auth, getToken, setToken, type UserResponse } from "../services/api";

export const useAuthStore = defineStore("auth", () => {
  const user = ref<UserResponse | null>(null);
  const ready = ref(false);
  const error = ref<string | null>(null);
  const busy = ref(false);

  // user.value must come first so the computed always tracks it as a dep —
  // when getToken() is null on first eval, `&&` would short-circuit and we'd
  // never read user.value, leaving the computed permanently stale.
  const isAuthed = computed(() => user.value !== null && !!getToken());

  async function hydrate() {
    if (ready.value) return;
    const token = getToken();
    if (!token) {
      ready.value = true;
      return;
    }
    try {
      user.value = await auth.me();
    } catch {
      setToken(null);
      user.value = null;
    } finally {
      ready.value = true;
    }
  }

  async function login(phone: string, password: string) {
    error.value = null;
    busy.value = true;
    try {
      const t = await auth.login(phone, password);
      setToken(t.access_token);
      user.value = await auth.me();
    } catch (e: any) {
      const msg = e?.response?.data?.detail || e?.message || "登录失败";
      error.value = String(msg);
      throw e;
    } finally {
      busy.value = false;
    }
  }

  async function register(phone: string, password: string) {
    error.value = null;
    busy.value = true;
    try {
      await auth.register(phone, password);
      // 注册成功后自动登录
      await login(phone, password);
    } catch (e: any) {
      const msg = e?.response?.data?.detail || e?.message || "注册失败";
      error.value = String(msg);
      throw e;
    } finally {
      busy.value = false;
    }
  }

  function logout() {
    setToken(null);
    user.value = null;
  }

  return { user, ready, error, busy, isAuthed, hydrate, login, register, logout };
});
