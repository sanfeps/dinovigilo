# Friends & Challenges — Plan completo

> Documento maestro de la feature "amigos + retos semanales". Mantener actualizado conforme avance la implementación. Permite retomar el trabajo en cualquier momento.

**Última actualización:** 2026-05-01
**Estado:** Fase 1 (backend) ✅ COMPLETA — endpoint HTTPS, superadmin y schema desplegados. Lista para Fase 2.

---

## ⏸ Punto de retoma (2026-05-01)

**Hecho hasta ahora en `openclaw-lab` (192.168.1.90 / tailnet `100.64.0.4`):**
- ✅ `/dev/net/tun` expuesto en config LXC
- ✅ Tailscale 1.96.4 instalado y conectado a `headscale.valgrindr.net` (user `dinovigilo`)
- ✅ PocketBase 0.37.4 en `/opt/pocketbase`, datos en `/var/lib/pocketbase/pb_data`, systemd `pocketbase.service` enabled, escuchando `127.0.0.1:8090`
- ✅ Caddy 2.11.2 con plugin `caddy-dns/njalla` arrancado y activo (`systemctl start caddy` ejecutado 2026-05-01)
- ✅ Cert Let's Encrypt emitido vía DNS-01 (issuer E8). Renovación automática.
- ✅ A record en Njalla: `pocketbase.valgrindr.net` → `100.64.0.4` propagado
- ✅ Token Njalla aplicado en `/etc/caddy/njalla.env` (perms `caddy:caddy 0600`)
- ✅ Endpoint verificado: `curl https://pocketbase.valgrindr.net/api/health` → `{"message":"API is healthy.","code":200}` desde dispositivo en tailnet
- ✅ Script `/usr/local/bin/pb-backup.sh` + cron diario 03:30, rotación 7 días, en `/var/backups/pocketbase/`. Test ejecutado correctamente.
- ✅ Superadmin creado vía CLI (`pocketbase superuser upsert`)
- ✅ Schema completo desplegado vía migración JS (`backend/pb_migrations/1777660800_init_friends_challenges.js`):
  - `users` extendida (username, displayName, avatarEmoji, optInScreenTime + UNIQUE idx_users_username)
  - `user_private` (separada del plan original — userId + inviteCode, no visible a amigos)
  - `friendships`, `challenges`, `challenge_objectives`, `challenge_completions`, `daily_summaries`
  - Reglas de acceso: `users` solo self; `daily_summaries` self + amigos aceptados; resto según plan
- ✅ Migración registrada en `_migrations`. Validación funcionando (signup pide username + email + password)
- ✅ Systemd actualizado con `--migrationsDir=/opt/pocketbase/pb_migrations` (migraciones futuras se aplican en restart)

**Sprint A (backend hooks) ✅ COMPLETO 2026-05-01:**
- ✅ `backend/pb_hooks/onUserCreate.pb.js` — auto-genera inviteCode único [A-Z0-9]{6} (alfabeto sin I/O/0/1) + crea record en `user_private` al signup. Helpers inlineados (PB pone cada hook en VM nueva del pool — funciones top-level no están en scope).
- ✅ `backend/pb_hooks/friendsByCode.pb.js` — endpoint `POST /api/friends/by-code` (auth requerida). Look-up via user_private, valida self/duplicate, crea friendship pending. Devuelve friend público (no expone tabla users).
- ✅ Test E2E: signup → user_private auto-creado → auth → POST /api/friends/by-code → friendship pending creada. Error cases (self-add 400, invalid 400, not-found 404, duplicate 400, unauth 401) todos cubiertos.
- Hooks viven en `/opt/pocketbase/pb_hooks/` (auto-reload via `--hooksWatch`).

**Sprint B (App auth foundation) ✅ COMPLETO 2026-05-01:**
- ✅ Deps añadidas: `pocketbase ^0.18.1`, `flutter_secure_storage ^9.2.2`
- ✅ `lib/core/constants/api_constants.dart` — `pocketBaseUrl` configurable vía `--dart-define=POCKETBASE_URL=...`, default `https://pocketbase.valgrindr.net`
- ✅ Clean architecture en `lib/features/auth/`:
  - `domain/entities/` — AuthUser, AuthSession (Freezed)
  - `domain/repositories/` — AuthRepository (interface)
  - `domain/usecases/` — SignIn, SignUp, SignOut
  - `data/datasources/` — AuthSecureStorage (FlutterSecureStorage), AuthRemoteDatasource (PocketBase + AsyncAuthStore persistido)
  - `data/repositories/` — AuthRepositoryImpl con mapping ClientException → typed Failures (NetworkFailure, AuthFailure, ValidationFailure con field errors extraídos, NotFoundFailure)
  - `presentation/providers/` — auth_providers.dart con keepAlive providers (storage, datasource, repository, authSession Stream) + use case providers
  - `presentation/screens/auth_screen.dart` — pantalla única con toggle Login/Signup. Validación inline (email, password ≥8, username/displayName en signup). FilledButton + loading state.
- ✅ Auth opcional: integrada en `SettingsScreen` como sección "Account" arriba de Notifications. Estado vacío muestra "Sign in to connect with friends" + botones Sign in/Sign up. Estado autenticado muestra avatar + displayName + @username + Sign out.
- ✅ l10n añadida a `app_en.arb` y `app_es.arb` (account, signIn, signUp, signOut, email, password, username, displayName, validaciones, etc.)
- ✅ `flutter analyze` limpio (solo deprecations en código generado de riverpod, esperado)
- ✅ **Smoke test E2E pasado 2026-05-01** vía SSH tunnel `openclaw-lab:8090 → localhost:8090` (laptop fuera del tailnet). Validado: signup, login con credenciales correctas (verde "Welcome back!" + signed-in card con avatar/displayName/@username), sign out (vuelve a "Not signed in"), login con password incorrecta (snackbar rojo "Invalid email or password" — mapping AuthFailure correcto).
- ⚠️ Keyring locked en NixOS dev → `flutter_secure_storage` writes fallan silenciosamente (wrapper tolerante en `auth_secure_storage.dart` los captura). Tokens NO persisten entre restarts en este dev box. Persistencia se valida en Android/móvil, no aquí.
- 🔧 Cambios infra: `flake.nix` ahora incluye `pkg-config gtk3 glib ninja clang xz libsecret` para Linux desktop builds. `linux/CMakeLists.txt` añade `-Wno-error=deprecated-literal-operator` (clang 17+ vs json.hpp bundled en flutter_secure_storage_linux).

**Sprint C (Friends UI) — siguiente:**
- Pantalla Amigos (sub-ruta, no tab)
- Mostrar mi código (leer de user_private)
- Add by code → POST /api/friends/by-code
- Lista friends + invitaciones pendientes (accept/reject)

---

---

## 1. Visión

Permitir a los usuarios conectarse con amigos y competir en **retos semanales 1v1** con objetivos comunes acordados. El que falle más días al final de la semana hace un objetivo de castigo (acordado de antemano) durante la siguiente semana.

**Principios:**
- Los retos viven en una pestaña separada — **no afectan** a la racha personal ni al sistema de huevos/dinos.
- Los objetivos del reto son **comunes** (acordados por ambos) — comparación justa.
- **One-shot** por semana — sin renovación automática, mantiene la tensión.
- Local-first: la app sigue funcionando offline; el backend solo orquesta el aspecto social.

---

## 2. Decisiones cerradas

| Tema | Decisión |
|---|---|
| Backend | **PocketBase self-hosted** (binario Go + SQLite). Migración a Supabase si crecemos >10k MAU. |
| VPS | Hetzner CX22 (~€4/mes), Caddy + HTTPS automático, systemd service, backup diario a B2/R2 |
| Auth | Email + password al principio. OAuth Google/Apple en una iteración posterior. |
| Cómo añadir amigos | Código de invitación de 6 dígitos |
| Arquitectura del reto | Pestaña separada con objetivos COMUNES, separada de objetivos personales |
| Cuántos objetivos | 1–5 por reto |
| Frecuencia de objetivos | Mismos los 7 días de la semana |
| Cómo se acuerda | **Asimétrica**: A propone N objetivos + castigo, B acepta o rechaza el paquete entero |
| Inicio del reto | Lunes siguiente al aceptar (00:00 hora local del usuario que acepta) |
| Definición de "día fallado" | El día tiene al menos un objetivo del reto sin marcar |
| Marcador final | Nº de días NO perfectos del reto. Pierde el que tenga más. |
| Empate | Nadie hace castigo (semana en blanco) |
| Tiebreaker futuro | Tiempo de pantalla del móvil. **Solo Android** (iOS no expone esa API). Opt-in. |
| Continuidad | One-shot, no auto-renovación. Para seguir, crear reto nuevo manualmente. |
| Visualización | Híbrido: edición en pestaña Challenges, banner en pestaña Today recordándolo |
| Realtime | Sí, ver el progreso del rival al instante (PocketBase realtime subs) |
| Castigo del perdedor | Se añade a sus objetivos personales 1 semana, etiquetado "Castigo de @amigo", desaparece solo |
| Privacidad | Los objetivos personales NO se exponen. Solo se comparte: racha, colección de dinos, resúmenes diarios (perfect day yes/no) |

---

## 3. Plan de implementación por fases

Cada fase es entregable y testeable por sí sola.

### ✅ Fase 0 — Diseño (este documento)
- Schema de PocketBase + reglas de acceso
- Cambios al schema local Drift
- Wireframes
- **Sin código todavía**

### Fase 1 — Backend mínimo
- Crear cuenta Hetzner, levantar VPS Ubuntu 24.04
- Instalar Caddy, PocketBase como systemd service
- Configurar dominio + HTTPS automático
- Cron de backup diario (`pb_data/data.db` → B2 con `restic` o `rclone`)
- Crear las colecciones del schema en el panel admin de PocketBase
- **Resultado:** backend accesible en `https://api.tudominio.com`

### Fase 2 — Auth + amistad
- Añadir dependencia `pocketbase` Dart SDK
- Pantalla de signup/login (email + password + username)
- Provider Riverpod para sesión
- Sincronizar perfil local
- Pantalla "Amigos" (lista + añadir por código de invitación)
- Generar y mostrar tu código de 6 dígitos
- Aceptar/rechazar invitaciones de amistad
- **Resultado:** dos personas pueden tener cuenta y ser amigos

### Fase 3 — Crear/aceptar retos
- Pantalla "Nuevo reto": elegir amigo, escribir 1-5 objetivos comunes, escribir castigo, enviar
- Bandeja de invitaciones (pendientes/aceptados/rechazados)
- Lista de retos en pestaña Challenges (activos, propuestos, históricos)
- **Resultado:** se pueden negociar y aceptar retos

### Fase 4 — Marcar y ver progreso (realtime)
- Pestaña "Challenges" con la cuadrícula 7×2 (días × jugadores)
- Marcar/desmarcar tus objetivos del reto
- Sincronización con PocketBase (`challenge_completions`)
- Realtime subscription al progreso del rival
- Banner híbrido en pestaña Today
- **Resultado:** competición funcional durante la semana

### Fase 5 — Cierre semanal y aplicación del castigo
- PocketBase JS hook (cron) que cada lunes 00:00 evalúa retos terminados
- Computa ganador/perdedor, marca `challenge.status = completed`
- App del perdedor: al sincronizar, detecta el resultado y añade el objetivo de castigo a su sprint local (tabla nueva `penalty_objectives`)
- Pantalla de resultado animada al abrir la app
- Limpieza automática del castigo el lunes siguiente
- **Resultado:** bucle cerrado, todo automático

### Fase 6 — Push notifications + pulido
- FCM para Android, APNs para iOS
- Notificaciones: nuevo reto recibido, rival completó día, último día del reto, resultado del reto
- Histórico de retos pasados (wall of fame)
- Animaciones de victoria/derrota
- Reacciones a check-ins de amigos (👏 🔥 etc)

### Fase 7 — Tiempo de pantalla (tiebreaker)
- Solo Android: integración con `UsageStatsManager` (paquete Flutter `app_usage` o similar)
- Permiso `PACKAGE_USAGE_STATS` con onboarding explicando por qué
- Sync diario de minutos a `daily_summaries.screenTimeMinutes`
- Lógica de desempate en el hook de cierre de Fase 5

### Fase 8 — Iteraciones futuras
- Castigos asimétricos (cada uno propone qué hará el otro)
- Grupos de retos (3+ participantes)
- OAuth Google/Apple
- Estadísticas de retos: win rate, racha de victorias
- Migración a Supabase si crecemos

---

## 4. Schema de PocketBase

### 4.1 Colecciones

#### `users` (built-in `auth` collection extendida)

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| email | string | (built-in, hidden) |
| username | string | único, lowercase, 3-20 chars, [a-z0-9_] |
| displayName | string | 1-30 chars, libre |
| avatarEmoji | string | un emoji (placeholder hasta que tengamos avatares reales) |
| inviteCode | string | 6 chars [A-Z0-9], único, regenerable |
| optInScreenTime | bool | default false, opt-in para tiebreaker futuro |
| createdAt | date | (built-in) |

**Reglas de acceso:**
- `listRule`: `id = @request.auth.id || @collection.friendships.userA = @request.auth.id && @collection.friendships.userB = id && @collection.friendships.status = "accepted"`
  *(Solo te ves a ti mismo o a tus amigos confirmados)*
- `viewRule`: igual que listRule
- `createRule`: `""` (público, vía endpoint de signup)
- `updateRule`: `id = @request.auth.id` (solo edita su propio perfil)
- `deleteRule`: `id = @request.auth.id`

**Campos visibles a amigos:** username, displayName, avatarEmoji
**Campos privados:** email, inviteCode (solo dueño), optInScreenTime

> ⚠️ Nota PocketBase: la visibilidad por campo se hace con `viewRule` distintos por colección o con `hidden` en el schema. Para campos como `inviteCode`, lo más limpio es separarlo a una colección `private_user_data` con accesos restringidos.

---

#### `friendships`

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| userA | relation(users) | el que envió la invitación |
| userB | relation(users) | el receptor |
| status | select | `pending` \| `accepted` \| `blocked` |
| createdAt | date | (built-in) |
| acceptedAt | date | nullable |

**Índice único:** `(userA, userB)` y constraint adicional: para una pareja {X, Y}, no puede haber dos filas (una con userA=X y otra con userA=Y simultáneamente). Se gestiona en lógica de creación.

**Reglas:**
- `listRule`/`viewRule`: `userA = @request.auth.id || userB = @request.auth.id`
- `createRule`: `userA = @request.auth.id` (solo creas invitaciones donde tú eres el invitador)
- `updateRule`: `userB = @request.auth.id && status = "pending"` (solo el receptor puede cambiar el estado a accepted/blocked)
- `deleteRule`: `userA = @request.auth.id || userB = @request.auth.id`

---

#### `challenges`

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| proposerId | relation(users) | el que crea el reto |
| opponentId | relation(users) | el invitado |
| status | select | `proposed` \| `active` \| `completed` \| `cancelled` \| `rejected` |
| weekStart | date | lunes 00:00 hora del proposer al aceptar |
| weekEnd | date | domingo 23:59 |
| penaltyObjective | text | 1-100 chars, lo que hará el perdedor |
| winnerId | relation(users) | nullable, set al cierre |
| loserId | relation(users) | nullable, set al cierre |
| isTie | bool | default false |
| penaltyApplied | bool | default false, true cuando el perdedor lo recibe en su app |
| createdAt | date | (built-in) |

**Reglas:**
- `listRule`/`viewRule`: `proposerId = @request.auth.id || opponentId = @request.auth.id`
- `createRule`: `proposerId = @request.auth.id && status = "proposed"`
- `updateRule`:
  - El opponent puede cambiar `status` de `proposed` a `active` (acepta) o a `rejected` (rechaza)
  - El proposer puede cambiar `status` de `proposed` a `cancelled` antes de aceptación
  - Una vez `active`, nadie modifica salvo el hook de cierre (server-side, bypass de reglas)
- `deleteRule`: ninguno (los retos quedan como histórico)

---

#### `challenge_objectives`

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| challengeId | relation(challenges) | |
| title | string | 1-100 chars |
| description | text | nullable, 0-500 chars |
| sortOrder | int | 0..4 para mantener orden |

**Reglas:**
- `listRule`/`viewRule`: `challengeId.proposerId = @request.auth.id || challengeId.opponentId = @request.auth.id`
- `createRule`: `challengeId.proposerId = @request.auth.id && challengeId.status = "proposed"`
- `updateRule`: igual al create (solo se editan en estado `proposed`, antes de aceptar)
- `deleteRule`: igual al create

---

#### `challenge_completions`

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| challengeId | relation(challenges) | |
| userId | relation(users) | |
| objectiveId | relation(challenge_objectives) | |
| date | date | día concreto (00:00 del día) |
| completed | bool | |
| updatedAt | date | (built-in) |

**Índice único:** `(challengeId, userId, objectiveId, date)`

**Reglas:**
- `listRule`/`viewRule`: `challengeId.proposerId = @request.auth.id || challengeId.opponentId = @request.auth.id`
  *(Ambos jugadores ven todos los completions del reto — clave para realtime)*
- `createRule`: `userId = @request.auth.id && challengeId.status = "active" && (challengeId.proposerId = @request.auth.id || challengeId.opponentId = @request.auth.id)`
- `updateRule`: `userId = @request.auth.id && challengeId.status = "active"`
- `deleteRule`: ninguno (los completions son histórico, ni siquiera el dueño los borra)

---

#### `daily_summaries` (para racha y feed social)

| Campo | Tipo | Notas |
|---|---|---|
| id | string | (built-in) |
| userId | relation(users) | |
| date | date | día (00:00) |
| perfectDay | bool | todos los objetivos personales completados |
| completedCount | int | objetivos personales completados ese día |
| totalCount | int | objetivos personales totales ese día |
| screenTimeMinutes | int | nullable, solo si optInScreenTime=true (Fase 7) |
| streakValue | int | racha del usuario al final de ese día |
| dinosaurCount | int | dinosaurios coleccionados al final de ese día |

**Índice único:** `(userId, date)`

**Reglas:**
- `listRule`/`viewRule`: `userId = @request.auth.id || @collection.friendships.userA = @request.auth.id && @collection.friendships.userB = userId && @collection.friendships.status = "accepted" || @collection.friendships.userB = @request.auth.id && @collection.friendships.userA = userId && @collection.friendships.status = "accepted"`
  *(Tú o tus amigos pueden verlo)*
- `createRule`/`updateRule`: `userId = @request.auth.id`
- `deleteRule`: `userId = @request.auth.id`

> 💡 Esta tabla sirve doble propósito: (a) feed social "ver el progreso de mis amigos", (b) tiebreaker de tiempo de pantalla, (c) si en el futuro queremos retos basados en datos personales (sin compartir contenido), ya está la infraestructura.

---

### 4.2 Hook server-side: cierre semanal

PocketBase permite hooks JS en `pb_hooks/`. Al desplegar, crear:

```javascript
// pb_hooks/close_challenges.pb.js
// Cron que corre cada lunes a las 00:05 UTC
cronAdd("closeWeeklyChallenges", "5 0 * * 1", () => {
    const now = new Date();
    const challenges = $app.findRecordsByFilter(
        "challenges",
        `status = "active" && weekEnd < "${now.toISOString()}"`
    );

    for (const ch of challenges) {
        // Para cada usuario, contar días no-perfectos en la semana
        const proposerFails = countFailedDays(ch, ch.get("proposerId"));
        const opponentFails = countFailedDays(ch, ch.get("opponentId"));

        if (proposerFails === opponentFails) {
            // Empate (o tiebreaker si ambos opt-in screen time — Fase 7)
            ch.set("isTie", true);
        } else if (proposerFails > opponentFails) {
            ch.set("loserId", ch.get("proposerId"));
            ch.set("winnerId", ch.get("opponentId"));
        } else {
            ch.set("loserId", ch.get("opponentId"));
            ch.set("winnerId", ch.get("proposerId"));
        }

        ch.set("status", "completed");
        $app.save(ch);
        // El cliente del perdedor verá el cambio al sincronizar y aplicará el castigo localmente
    }
});

function countFailedDays(challenge, userId) {
    // Para cada uno de los 7 días, contar si TODOS los objetivos están completed=true
    // Si falta alguno, ese día cuenta como fallado
    // ... (detalle a implementar en Fase 5)
}
```

> Decisión: el cierre semanal es **server-side** porque:
> - Garantiza que ocurre incluso si nadie abre la app
> - Evita race conditions (dos clientes intentando cerrar a la vez)
> - El cliente solo necesita "leer" el resultado y aplicar el castigo localmente

---

## 5. Cambios al schema local (Drift)

### 5.1 Tabla nueva: `penalty_objectives`

Objetivo de castigo recibido tras perder un reto. Se renderiza en Today junto con los objetivos personales pero es transitorio (1 semana, desaparece solo).

```dart
// lib/core/database/tables.dart

@DataClassName('PenaltyObjectiveRow')
class PenaltyObjectives extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get fromUsername => text()();        // "Pepe" para mostrar "Castigo de Pepe"
  TextColumn get sourceChallengeId => text()();    // referencia al reto remoto
  DateTimeColumn get weekStart => dateTime()();    // lunes 00:00 de la semana en que aplica
  DateTimeColumn get weekEnd => dateTime()();      // domingo 23:59
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Migración:** schema v6 → v7, simplemente añade la tabla.

### 5.2 Modificación a `DailyCompletions`

Añadir columna opcional para distinguir completions de penalty:

```dart
TextColumn get penaltyObjectiveId => text().nullable()();
```

- Si `objectiveId` está set: completion de objetivo personal normal
- Si `penaltyObjectiveId` está set: completion de objetivo de castigo
- Estos completions del castigo **sí cuentan** para el día perfecto del usuario perdedor (porque ya forman parte de sus objetivos durante esa semana)

### 5.3 Lógica en Today

Pseudocódigo del provider que devuelve los objetivos de hoy:

```dart
@riverpod
Future<List<TodayObjective>> todayObjectives(TodayObjectivesRef ref) async {
  final today = DateTime.now();
  final personalObjectives = await getObjectivesForDayUseCase.execute(today);
  final activePenalties = await penaltyRepository.getActiveForDate(today);

  return [
    ...personalObjectives.map((o) => TodayObjective.personal(o)),
    ...activePenalties.map((p) => TodayObjective.penalty(p)),
  ];
}
```

`TodayObjective` es un sealed/freezed con dos variantes (`personal` vs `penalty`) para que la UI pinte la badge "Castigo de @Pepe" en las penalty.

### 5.4 Limpieza automática

Hook al iniciar app (o al pasar de medianoche): borrar penalties cuyo `weekEnd < now`.

```dart
// En core_providers.dart o equivalente
Future<void> _cleanupExpiredPenalties() async {
  final now = DateTime.now();
  await db.delete(db.penaltyObjectives)
    ..where((t) => t.weekEnd.isSmallerThanValue(now));
  // Las completions huérfanas con penaltyObjectiveId quedan, son histórico
}
```

---

## 6. Wireframes

ASCII-art aproximado, ajustar a Material 3 al implementar.

### 6.1 Pestaña Challenges (sin retos activos)

```
┌─────────────────────────────────────┐
│  ←  Retos                           │
├─────────────────────────────────────┤
│                                     │
│         🏆                          │
│                                     │
│   No tienes retos activos           │
│                                     │
│   Compite con un amigo y demuestra  │
│   quién es más constante esta       │
│   semana.                           │
│                                     │
│   ┌─────────────────────────────┐   │
│   │     + Nuevo reto            │   │
│   └─────────────────────────────┘   │
│                                     │
│   ▼ Invitaciones recibidas (2)      │
│   ┌─────────────────────────────┐   │
│   │ @pepe te ha retado           │   │
│   │ "30 min ejercicio + leer..."  │   │
│   │      [Ver]    [Rechazar]      │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 6.2 Pestaña Challenges (con reto activo)

```
┌─────────────────────────────────────┐
│  ←  Retos             [+]           │
├─────────────────────────────────────┤
│                                     │
│  🔥 Reto con @pepe                  │
│  Quedan 3 días                      │
│                                     │
│  Marcador:  Tú 1 ❌  ·  Pepe 0 ❌   │
│                                     │
│  Objetivos:                         │
│  • 30 min ejercicio                 │
│  • Leer 20 min                      │
│  • Sin azúcar                       │
│                                     │
│  Castigo: hacer 100 flexiones       │
│           todos los días la próxima │
│           semana                    │
│                                     │
│        L  M  X  J  V  S  D          │
│   Tú   ✅ ✅ ❌ ⚪ ⚪ ⚪ ⚪          │
│   Pepe ✅ ✅ ✅ ⚪ ⚪ ⚪ ⚪          │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Marcar mi día (jueves)      │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 6.3 Marcar mi día (modal o pantalla)

```
┌─────────────────────────────────────┐
│  ←  Jueves                          │
├─────────────────────────────────────┤
│                                     │
│  Marca lo que has cumplido hoy:     │
│                                     │
│  [✓]  30 min ejercicio              │
│  [✓]  Leer 20 min                   │
│  [ ]  Sin azúcar                    │
│                                     │
│  💡 Si no marcas todos antes de      │
│     medianoche, el día cuenta como  │
│     fallado.                        │
│                                     │
│         [Cerrar]                    │
│                                     │
└─────────────────────────────────────┘
```

### 6.4 Crear reto

```
┌─────────────────────────────────────┐
│  ←  Nuevo reto                      │
├─────────────────────────────────────┤
│                                     │
│  Rival                              │
│  ┌─────────────────────────────┐   │
│  │ @pepe                    ▼   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Objetivos comunes (1-5)            │
│  ┌─────────────────────────────┐   │
│  │ 30 min ejercicio        [✕]  │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Leer 20 min             [✕]  │   │
│  └─────────────────────────────┘   │
│  [ + Añadir objetivo ]              │
│                                     │
│  Castigo (lo hace el perdedor)      │
│  ┌─────────────────────────────┐   │
│  │ 100 flexiones diarias        │   │
│  └─────────────────────────────┘   │
│                                     │
│  El reto empieza el próximo lunes.  │
│                                     │
│   ┌─────────────────────────────┐   │
│   │       Enviar reto            │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 6.5 Banner en pestaña Today

```
┌─────────────────────────────────────┐
│  Hoy — Jueves 30 abril              │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔥 Reto con @pepe             │   │  ← tap → va a pestaña Challenges
│  │    Tú 1❌ · Pepe 0❌  →        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Tus objetivos                      │
│  [✓] Meditar 10 min                 │
│  [ ] Estudiar inglés                │
│                                     │
│  ⚠ Castigo de @pepe (semana)        │
│  [ ] 100 flexiones                  │
│                                     │
└─────────────────────────────────────┘
```

### 6.6 Resultado fin de semana (modal al abrir app)

```
┌─────────────────────────────────────┐
│                                     │
│            🏆                        │
│                                     │
│       ¡Has ganado!                  │
│                                     │
│  Pepe falló 3 días, tú solo 1.      │
│                                     │
│  Ahora él tendrá que hacer:         │
│  ┌─────────────────────────────┐   │
│  │ 100 flexiones diarias        │   │
│  └─────────────────────────────┘   │
│                                     │
│  durante toda la próxima semana.    │
│                                     │
│   ┌─────────────────────────────┐   │
│   │           ¡Genial!           │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

Versión perdedor:

```
┌─────────────────────────────────────┐
│                                     │
│            😢                        │
│                                     │
│    Esta semana toca currar          │
│                                     │
│  Has fallado 3 días, Pepe solo 1.   │
│                                     │
│  Esta semana tienes que hacer:      │
│  ┌─────────────────────────────┐   │
│  │ 100 flexiones diarias        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Aparecerá en tus objetivos.        │
│                                     │
│   ┌─────────────────────────────┐   │
│   │      ¡La semana que viene!   │   │
│   └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 6.7 Amigos

```
┌─────────────────────────────────────┐
│  ←  Amigos                          │
├─────────────────────────────────────┤
│                                     │
│  Tu código de invitación            │
│  ┌─────────────────────────────┐   │
│  │      A B 7 K 2 9             │   │
│  │   [Copiar]   [Compartir]     │   │
│  └─────────────────────────────┘   │
│                                     │
│  Añadir amigo por código            │
│  ┌─────────────────────────────┐   │
│  │ ______           [Añadir]    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Mis amigos (3)                     │
│  ┌─────────────────────────────┐   │
│  │ 🦖 @pepe                     │   │
│  │    Racha: 12 · Dinos: 7      │   │
│  │                       [···]  │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🦕 @maria                    │   │
│  │    Racha: 0 · Dinos: 2       │   │
│  │                       [···]  │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. Cambios al `_HomeScreen` (navegación)

Estructura actual de tabs (lib/app.dart):

| Index | Tab |
|---|---|
| 0 | History |
| 1 | Sprint |
| 2 | Today (default) |
| 3 | Incubator |
| 4 | Collection |
| 5 | Debug (temp) |

Estructura propuesta tras la feature:

| Index | Tab |
|---|---|
| 0 | History |
| 1 | Sprint |
| 2 | Today (default) |
| 3 | **Challenges** ← NUEVO |
| 4 | Incubator |
| 5 | Collection |
| (debug se quita en release) |

La pestaña "Amigos" no es un tab principal — vive como sub-screen accesible desde:
- Settings → "Amigos y retos"
- Botón en el header de la pestaña Challenges

---

## 8. Estrategia de testing

### Manual (durante desarrollo)
- Dos cuentas en dos dispositivos (o emulador + físico)
- Aceleración de tiempo: feature flag o botón debug que adelanta `weekEnd` a "ahora" para probar el cierre

### Automatizado
- Tests de la lógica de cierre semanal (countFailedDays, tiebreaker, empate)
- Tests del repositorio de penalties (alta, expiración, listado por semana)
- Tests del provider `todayObjectives` con penalties activos

---

## 9. Riesgos / cosas a vigilar

1. **Realtime de PocketBase con sleep/background app**: las suscripciones se cierran. Re-suscribir al volver al foreground.
2. **Conflictos de zona horaria**: `weekStart`/`weekEnd` deben ser claros — propuesta: usar la zona horaria del que **acepta** el reto, no del que propone.
3. **Sync offline**: si marcas un objetivo del reto sin conexión, debe encolarse y sincronizar al volver. PocketBase no lo hace solo — usar `drift` local + cola de operaciones pendientes.
4. **Penalties huérfanos**: si el server falla en cerrar un reto, el cliente debe tener fallback (al abrir la app, si encuentra retos `active` con `weekEnd < now`, intentar cerrarlos vía endpoint).
5. **Spam de invitaciones**: rate-limiting en PocketBase (max 5 friend requests/día por user).
6. **Cuenta abandonada**: si un user no abre la app durante el reto, sus objetivos aparecen como fallados (correcto). Si nunca acepta el reto, expira a los 7 días → status = `cancelled`.
7. **Escapes de seguridad en `penaltyObjective` y `title`**: text libre que se renderiza en otra app. Sanitizar en cliente antes de renderizar (Flutter por defecto no interpreta HTML, pero ojo con copy-paste de URLs y caracteres invisibles).

---

## 10. Coste estimado

| Item | Coste/mes |
|---|---|
| VPS Hetzner CX22 | €4.51 |
| Backups B2 (10 GB) | €0 (free tier) |
| Dominio (.com) | €1 (€12/año) |
| Push (FCM) | €0 |
| Push (APNs) | €0 (cuenta dev Apple ya pagada) |
| **Total** | **~€6/mes** |

Cuenta de desarrollador Apple ($99/año) es necesaria para iOS pero no es coste de esta feature — ya hace falta para publicar la app.

---

## 11. Próximos pasos inmediatos

1. ✅ Cerrar Fase 0 (este documento) — **HECHO**
2. ⏭ Revisar el documento contigo y ajustar lo que haga falta
3. ⏭ Empezar Fase 1: contratar VPS y desplegar PocketBase

Cuando estemos listos para Fase 1, lo primero será:
- Decidir nombre de dominio
- Crear cuenta Hetzner
- Tener listo el contenido de `flake.nix` con herramientas para deploy (opcional pero recomendado)
