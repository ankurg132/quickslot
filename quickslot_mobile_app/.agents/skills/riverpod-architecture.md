---
name: riverpod-architecture
description: >
  Generates and enforces Riverpod architecture for Flutter apps and features.
  Use when the user asks to design, scaffold, or plan a Flutter/Riverpod app,
  OR when the user asks to implement, add, or build a new feature inside an
  existing Flutter/Riverpod project.
---

# Riverpod Architecture Skill

You are a **senior Flutter architect** when this skill is active. Every rule in this file is mandatory. No rule is optional unless the user explicitly overrides it. Both whole-app architecture and individual feature implementation are treated with the same strictness — a new feature is a mini-architecture.

## When to use this skill

**Architecture triggers** (whole-app design):
- User says "architecture", "structure", "scaffold", "set up", "design", "plan" combined with "Riverpod", "Flutter app", "Flutter project", "provider", or "notifier"
- User shares a list of app requirements and asks how to implement them in Flutter/Riverpod

**Feature triggers** (adding to an existing app):
- User says "add a feature", "implement", "build a", "create a", "I need a … screen/page/flow"
- User says "how do I add X to my app", "implement X in Riverpod", "write the code for X"
- User describes a user story or screen and asks for the Riverpod implementation
- User pastes existing code and asks to extend it with new functionality

When triggered by a **feature request**, apply the Feature Implementation Mode section in addition to all standard rules.

## How to use this skill

### Mandatory pre-response checklist

Before writing a single line of code, internally verify every item below. Your output must satisfy all of them.

**Layer checklist**
- [ ] Is every data source (HTTP, DB, cache) isolated in a Repository class?
- [ ] Is every Repository exposed via a `Provider` with constructor injection?
- [ ] Does every Notifier talk only to Repositories — never raw `http` or `dio`?
- [ ] Are all state classes immutable (`freezed` or manual `copyWith`)?
- [ ] Is the UI layer free of business logic?

**Provider checklist**
- [ ] Is `ref.watch` used only inside `build()` methods?
- [ ] Is `ref.read` used only inside action methods / callbacks?
- [ ] Is `ref.listen` used for all one-off UI side-effects (navigation, snackbars, dialogs)?
- [ ] Are all screen-scoped providers marked `.autoDispose`?
- [ ] Are all providers that need arguments using `.family`?
- [ ] Are there any circular dependencies? If yes, is a third shared provider extracted?

**State checklist**
- [ ] Does every async data-fetching provider return `AsyncValue<T>`?
- [ ] Does every async UI widget use `.when()` to handle loading / error / data?
- [ ] Are mutations using `AsyncValue.guard()` instead of raw try-catch?
- [ ] Are optimistic updates saving `previousState` before mutation?

**Architecture checklist**
- [ ] Is routing handled by a `routerProvider` that `ref.watch`es auth state?
- [ ] Is there no global `ProviderContainer` in Flutter code?
- [ ] Is there no `Navigator` or `showDialog` inside any Notifier?
- [ ] Are Riverpod providers used as the DI system (no `get_it` unless explicitly requested)?

---

### Mandatory output format — whole-app architecture

When the user asks to design a whole app, always output in this exact order.

#### 1. Layer map

Always show this diagram first, annotated with what each layer IS and IS NOT allowed to do:

```
UI (Widgets / Screens)
        │  ref.watch / ref.listen
        ▼
Notifiers / AsyncNotifiers        ← state logic only, no HTTP
        │  ref.read(repositoryProvider)
        ▼
Repositories                      ← data assembly, caching, model mapping
        │  injected via constructor
        ▼
Data Sources                      ← raw HTTP clients, local DB, device APIs
```

#### 2. Provider dependency graph

List every provider and what it depends on:

```
networkClientProvider       (Provider)               → no deps
userRepositoryProvider      (Provider)               → networkClientProvider
authNotifierProvider        (AsyncNotifierProvider)  → userRepositoryProvider
routerProvider              (Provider<GoRouter>)     → authNotifierProvider
```

Flag any provider that does NOT use `.autoDispose` and explain why it is a long-lived singleton.

#### 3. State class definitions

For every feature, define the state class using `freezed` or manual `copyWith`. Never use mutable classes.

```dart
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<CartItem> items,
    @Default(false) bool isCheckingOut,
    String? errorMessage,
  }) = _CartState;
}
```

#### 4. Notifier skeletons

Write every Notifier skeleton. Enforce in every skeleton:
- `build()` returns initial state or fetches from repository only
- Methods use `AsyncValue.guard()` for async mutations
- No `http`, `dio`, or raw DB calls — only repository method calls
- No `Navigator`, `showDialog`, `ScaffoldMessenger`

```dart
class CartNotifier extends AsyncNotifier<CartState> {
  @override
  Future<CartState> build() async {
    return ref.read(cartRepositoryProvider).loadCart();
  }

  Future<void> addItem(CartItem item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cartRepositoryProvider).addItem(item, current: state.requireValue),
    );
  }
}
```

#### 5. Repository skeletons

Write every Repository with an abstract interface and an implementation. Pure Dart — zero Flutter imports.

```dart
abstract class CartRepository {
  Future<CartState> loadCart();
  Future<CartState> addItem(CartItem item, {required CartState current});
}

class CartRepositoryImpl implements CartRepository {
  final ApiClient _client;
  CartRepositoryImpl(this._client);

  @override
  Future<CartState> loadCart() async {
    final json = await _client.get('/cart');
    return CartState.fromJson(json);
  }
}
```

#### 6. UI wiring

Show how each screen connects. Enforce:
- `ConsumerWidget` or `ConsumerStatefulWidget` for all screens that read state
- `.when()` on every `AsyncValue`
- `ref.listen` for every navigation or snackbar trigger
- `.select()` on any widget that only needs one field from a larger state object

```dart
class CartScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<CartState>>(cartNotifierProvider, (_, next) {
      if (next.value?.isCheckingOut == false && next.hasValue) {
        Navigator.of(context).pushNamed('/confirmation');
      }
    });

    final cartAsync = ref.watch(cartNotifierProvider);
    return cartAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (cart) => CartListView(items: cart.items),
    );
  }
}
```

#### 7. Routing setup

Always use `GoRouter` inside a `routerProvider`. Always connect it to the auth state provider.

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authNotifierProvider);

  return GoRouter(
    redirect: (context, state) {
      final loggedIn = auth.valueOrNull?.isAuthenticated ?? false;
      final goingToLogin = state.matchedLocation == '/login';
      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/home';
      return null;
    },
    routes: [ /* routes here */ ],
  );
});
```

#### 8. Folder structure

Always recommend this structure:

```
lib/
├── main.dart
├── app/
│   ├── router.dart              ← routerProvider (GoRouter)
│   └── app.dart                 ← ProviderScope root, MaterialApp.router
├── core/
│   ├── network/
│   │   └── api_client.dart      ← raw HTTP client, apiClientProvider
│   └── storage/
│       └── local_storage.dart   ← SharedPrefs / Hive wrapper
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── [feature]_repository.dart        ← abstract interface
│       │   └── [feature]_repository_impl.dart   ← implementation
│       ├── domain/
│       │   └── [feature]_state.dart             ← freezed state class
│       ├── application/
│       │   └── [feature]_notifier.dart          ← AsyncNotifier
│       └── presentation/
│           ├── [feature]_screen.dart            ← ConsumerWidget screen
│           └── widgets/                         ← smaller ConsumerWidgets
└── shared/
    ├── providers/               ← cross-feature providers (auth, theme)
    └── widgets/                 ← reusable UI components
```

---

### Mandatory output format — feature implementation

When the user asks to add or implement a specific feature, always output in this exact order.

#### Step 1 — Scope the feature into layers

Before writing any code, explicitly state what each layer will contain:

```
Feature: [Name]

Data Source : [API endpoint / DB table / device API]
Repository  : [method signatures and return models]
Notifier    : [state type, initial state, public methods]
UI          : [screens/widgets, action triggers, side-effects]
```

Never skip this step.

#### Step 2 — Check integration points

Explicitly name how the feature connects to the existing app:
- Which existing providers does this feature **read** from? (`ref.read`)
- Which existing providers does this feature **watch** reactively? (`ref.watch`)
- Does this feature risk a **circular dependency**? If yes, resolve it before writing code.
- Does this feature need to trigger a **side-effect** in another feature's UI? If yes, use `ref.listen`.

#### Step 3 — Decide provider lifetime

For every new provider, state the lifetime choice explicitly:

| Provider | `.autoDispose`? | Reason |
|---|---|---|
| `searchNotifierProvider` | ✅ Yes | Screen-scoped; state should reset on exit |
| `cartNotifierProvider` | ❌ No | Global — persists across all screens |

Default rule: **screen-scoped = autoDispose, app-wide = no autoDispose**.

#### Step 4 — Write in layer order

Always write files in this order:
1. State class (`domain/[feature]_state.dart`)
2. Repository interface + implementation (`data/`)
3. Repository provider
4. Notifier + NotifierProvider (`application/[feature]_notifier.dart`)
5. Screen / widgets (`presentation/`)

Never write the screen before the notifier. Never write the notifier before the repository.

#### Step 5 — Summarise files created

End every feature implementation with:

```
Files created / modified:
  NEW  lib/features/search/domain/search_state.dart
  NEW  lib/features/search/data/search_repository.dart
  NEW  lib/features/search/application/search_notifier.dart
  NEW  lib/features/search/presentation/search_screen.dart
  MOD  lib/app/router.dart   ← added /search route
```

---

### Pattern rules (apply automatically — never ask the user)

**Repository pattern — ALWAYS**
Never let a Notifier call `http`, `dio`, `sqflite`, or `SharedPreferences` directly. Always insert a Repository layer.

**Immutability — ALWAYS**
Never design a state class with mutable fields. Use `freezed` or show `copyWith`. Replace lists with spreads, never `.add()`.

**AsyncValue — ALWAYS for I/O**
Any provider that fetches from network or local DB returns `AsyncValue<T>`. Any widget consuming it uses `.when()`. No manual `isLoading` booleans on state classes.

**autoDispose — ALWAYS for screen-scoped providers**
Screen-scoped providers get `.autoDispose`. Global providers (auth, theme, cart, user session) do not.

**ref.listen for side-effects — ALWAYS**
Any state change that should trigger navigation, a snackbar, or a dialog uses `ref.listen` in the widget — never inside a Notifier.

**Optimistic UI — when user action should feel instant**
For toggles, likes, bookmarks, or boolean flips: save `previousState`, update immediately, roll back on error.

**.select — when a widget uses only one field**
If a widget only displays one property from a larger object, use `.select`. Call this out explicitly in architecture comments.

**.family — when a provider needs an argument**
Any provider that needs a record ID, user ID, or filter parameter uses `.family`. Pair with `.autoDispose`.

**Scoped providers — for list items with independent state**
When a `ListView` renders items that each need their own state controller: use `ProviderScope` overrides per item instead of constructor drilling.

**Route guards — ALWAYS when app has authentication**
Always design a `routerProvider` that `ref.watch`es auth state and redirects automatically on login/logout.

---

### Layer permission table

Use this when deciding where a piece of code belongs. When in doubt, this table is the final answer.

| Action | Data Source | Repository | Notifier | Widget |
|---|---|---|---|---|
| Raw HTTP / SQL call | ✅ | ❌ | ❌ | ❌ |
| JSON → Model mapping | ❌ | ✅ | ❌ | ❌ |
| Caching logic | ❌ | ✅ | ❌ | ❌ |
| Business rules / validation | ❌ | ❌ | ✅ | ❌ |
| State mutation | ❌ | ❌ | ✅ | ❌ |
| `ref.watch` | ❌ | ❌ | ✅ build() only | ✅ build() only |
| `ref.read` | ❌ | ❌ | ✅ methods only | ✅ callbacks only |
| `ref.listen` | ❌ | ❌ | ❌ | ✅ |
| Navigation / Dialogs | ❌ | ❌ | ❌ | ✅ |
| `AsyncValue.guard` | ❌ | ❌ | ✅ | ❌ |
| `copyWith` / spread | ❌ | ❌ | ✅ | ❌ |

---

### Anti-pattern enforcement

If the user's existing code or requirements imply any of these, **flag them explicitly** before producing corrected code. Never silently fix a violation without naming it.

| Detected anti-pattern | What to say | What to do instead |
|---|---|---|
| `http.get` inside a Notifier | "HTTP calls belong in the Repository layer, not the Notifier." | Move to Repository, inject via provider |
| `Navigator.push` inside a Notifier | "Navigation is a UI side-effect. Notifiers cannot hold BuildContext." | Use `ref.listen` in the widget |
| `state.list.add(item)` | "This mutates in-place. Riverpod won't detect the change." | `state = state.copyWith(list: [...state.list, item])` |
| `isLoading: true` boolean on state | "Use `AsyncValue<T>` instead of manual loading flags." | Replace with `AsyncNotifier<T>` |
| `ref.watch` inside a button callback | "`ref.watch` in a callback causes memory leaks and missed updates." | Use `ref.read` in callbacks |
| Global `ProviderContainer` variable | "This bypasses Riverpod's scoping and breaks test isolation." | Turn the class into a Provider |
| Two providers watching each other | "Circular dependency — app will freeze on init." | Extract shared state to a third provider |
| `get_it` alongside Riverpod | "Riverpod is already a DI framework. Two registries create confusion." | Use Riverpod providers for injection |

---

### Provider type quick reference

| Use case | Provider type |
|---|---|
| Immutable service / repository | `Provider<T>` |
| Simple synchronous state | `NotifierProvider<T>` |
| State loaded from network / DB | `AsyncNotifierProvider<T>` |
| State that resets when screen closes | Add `.autoDispose` |
| Provider needing an argument (ID, filter) | Add `.family` |
| Screen-scoped + async + parameterized | `AsyncNotifierProvider.autoDispose.family` |
| Derived / computed value from other providers | `Provider<T>` with `ref.watch` inside |
| Listening to a stream (WebSocket, Firestore) | `StreamNotifierProvider<T>` |
