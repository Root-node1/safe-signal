// Prototype mode flag. Reports and assistant calls still use the backend API; this flag only
// shows the "Prototype" badge and allows the mock-data admin screen (/#admin) to render.
// It is a build-time cosmetic setting, NOT an authorization mechanism: anyone can read the
// bundle. Production builds must set VITE_PROTOTYPE=false, and real admin access must be
// enforced by the backend (SAFESIGNAL_ADMIN_KEY / sign-in), never by this flag.
export const PROTOTYPE: boolean = import.meta.env.VITE_PROTOTYPE !== "false";
