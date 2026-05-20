import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "../stores/auth";

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to, _from, saved) {
    if (saved) return saved;
    if (to.hash) return { el: to.hash, behavior: "smooth" };
    return { top: 0, behavior: "instant" as ScrollBehavior };
  },
  routes: [
    {
      path: "/",
      name: "landing",
      component: () => import("../pages/LandingPage.vue"),
    },
    {
      path: "/login",
      name: "login",
      component: () => import("../pages/LoginPage.vue"),
      meta: { guest: true },
    },
    {
      path: "/chat",
      name: "chat",
      component: () => import("../pages/ChatPage.vue"),
      meta: { auth: true },
    },
    {
      path: "/history",
      name: "history",
      component: () => import("../pages/HistoryPage.vue"),
      meta: { auth: true },
    },
    {
      path: "/profile",
      name: "profile",
      component: () => import("../pages/ProfilePage.vue"),
      meta: { auth: true },
    },
    {
      path: "/records",
      name: "records",
      component: () => import("../pages/RecordsPage.vue"),
      meta: { auth: true },
    },
    {
      path: "/call",
      name: "call",
      component: () => import("../pages/CallPage.vue"),
      meta: { auth: true },
    },
    { path: "/:catchAll(.*)", redirect: "/" },
  ],
});

router.beforeEach(async (to) => {
  const a = useAuthStore();
  if (!a.ready) await a.hydrate();

  if (to.meta.auth && !a.isAuthed) {
    return { name: "login", query: { from: to.fullPath } };
  }
  if (to.meta.guest && a.isAuthed) {
    return { name: "chat" };
  }
});

export default router;
