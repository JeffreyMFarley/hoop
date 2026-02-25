# Frontend Agent Implementation Rules

**IMPORTANT:** These rules are for Frontend Execute Agents working on specific chunks from a feature plan. For new features or complex changes, use the Plan Agent first.

## Per-File Implementation Loop

For EACH individual file, follow this exact sequence:

### Step 1: Pattern Check

- Review the pattern rules in frontend-agent.md for this file type
- Identify which specific rules apply to this file

### Step 2: Similar Files Analysis

- Find 3-5 existing files of the same type in the project
- Study their structure, naming, and implementation patterns
- Note the exact conventions they follow
- **NEVER assume components/imports exist - always verify exact names and paths**

### Step 3: Implement File

- **Check that all imports/components you want to use actually exist first**
- Create the single file following the patterns discovered
- Use the exact naming, structure, and style from similar files
- **Verify component names and import paths before using them**

### Step 4: Verify Pattern Match

- Compare the new file against the pattern rules in frontend-agent.md
- Ensure it follows the same conventions as existing similar files
- **Verify file is in the correct folder** following project structure
- **Verify all imports are correct** and follow project import patterns
- Fix any deviations immediately

### Step 5: Verify Types

- **Use VSCode MCP server getDiagnostics if available** for efficient type checking
- If MCP not available, check that types compile correctly
- Ensure TypeScript (if used) passes for this file
- Fix any type errors

### Step 6: Write Test (MANDATORY if project has tests)

- **NEVER skip this step** - always check if similar files have tests
- If project has tests for similar files, **YOU MUST write test for this file**
- Follow the same testing patterns used in the project
- **Run the test for THIS FILE ONLY** to verify it passes

### Step 7: App Integration (for pages/features)

- **If creating a page component:** Add route to router configuration
- **If creating a page component:** Add navigation link if needed
- **If component needs data:** Implement API calls following project patterns
- **If component needs data:** Add proper loading/error states
- **If feature requires permissions:** Check if existing permission applies or ask user if new permission needed
- Verify the feature works end-to-end in the app

### Step 8: Final Validation, Verification and Documentation

- **Use VSCode MCP server getDiagnostics if available** for final type/lint checking
- **Run linting tools on this single file** - must pass
- **Run type checking on this single file** - must pass
- Verify the file integrates with existing code
- **Verify pattern compliance:** Confirm this file follows ALL applicable pattern rules
- **Verify requirements:** Confirm this file meets the original feature requirements
- **Document the feature:** Create/update documentation following project documentation patterns
- **ONLY IF ALL CHECKS PASS:** Mark this file as truly complete

## CRITICAL: ONE FILE AT A TIME ONLY

- **NEVER create multiple files in one response**
- **NEVER say "Now let me create the next component"**
- **COMPLETE ALL 8 STEPS for the current file BEFORE even mentioning another file**
- **MUST run lint and type check on THIS FILE before moving on**
- **MUST run any tests written for THIS FILE before moving on**
- Each file must go through: pattern check → analysis → implement → verify → types → test → integrate → final validation & documentation
- Only after all 8 steps pass completely should you consider the next file

---

## Frontend Patterns - Hoop (AWS Scaffolding Demo)

### Aspect 1: Component Structure and Naming

1. Components are plain JavaScript function declarations (not arrow functions, not class components) exported as `export default function ComponentName()`. Example from `services/ui/src/components/Fortune.js`: `export default function Fortune()`. The eslint rule `func-style` is set to `declaration` with `allowArrowFunctions: true`, reinforcing this pattern.

2. Component file names use PascalCase that matches the exported function name exactly. Examples: `Footer.js` exports `FooterPanel`, `Fortune.js` exports `Fortune`, `Header.js` exports `HeaderPanel`, `Names.js` exports `Names`. Note that Footer and Header use a "Panel" suffix on the function name even though the file is named without it - new components should follow the function-name-in-file pattern that matches the file name (as Fortune and Names do).

3. Helper render functions are extracted as named exports alongside the default component export. In `Fortune.js`: `export function renderFortune(response, mode, err)` lives in the same file as `export default function Fortune()`. In `Names.js`: `export function renderNames(response, mode, err, kind)` lives with `export default function Names(props)`. These render helpers take the same `(response, mode, err)` signature pattern as the hook returns.

4. Non-page helper functions and sub-route components are defined in the same file as their parent and placed after the default export. In `App.js`, `function NamesRoute()` is defined after `export default function App()` at the bottom of the file.

5. Shared data/constants that are used by multiple files are exported from the component file that owns them. Example: `export const apiMap` is defined in `Names.js` and imported into `Header.js` via `import { apiMap } from './Names'`.

### Aspect 2: File Organization

6. The source tree follows a flat two-level structure: `src/` contains top-level files (`App.js`, `index.js`, `base.css`, `index.html`) and two subdirectories: `src/components/` for React components and `src/hooks/` for custom hooks. There is no `pages/`, `utils/`, `services/`, `contexts/`, or `store/` directory.

7. Test files for hooks live in `src/hooks/__tests__/` using the naming convention `hookName.test.js`. The only test file is `src/hooks/__tests__/useFetch.test.js`. Component tests (if any) would follow the same pattern in `src/components/__tests__/`.

8. Jest mock files live in `src/__mocks__/` with specific names: `fileMock.js` for binary assets (images, fonts, SVGs) and `styleMock.js` for CSS files. These are referenced in `package.json` under `jest.moduleNameMapper`.

9. The HTML entry point is `src/index.html` (not `public/index.html` as in create-react-app). Webpack uses this as its template via `HtmlWebPackPlugin`. The root DOM element uses `id="app"` (not `id="root"`).

10. Configuration files (`.babelrc`, `.eslintrc`, `webpack.config.js`, `package.json`) all live at the `services/ui/` level, not in `src/`.

### Aspect 3: Styling Approach

11. The project uses USWDS (U.S. Web Design System) exclusively for all styling, delivered through the `@trussworks/react-uswds` component library. No custom CSS files exist for individual components - all styling is done via USWDS utility class names applied directly as `className` props.

12. The single `src/base.css` file imports the entire USWDS stylesheet package: `@import '~@trussworks/react-uswds/lib/uswds.css'` and `@import '~@trussworks/react-uswds/lib/index.css'`. This is the only CSS file. It is imported once in `src/index.js`.

13. Layout uses USWDS grid utility classes directly on JSX elements. Example from `Fortune.js`: `<section className="grid-container usa-section">`, `<Grid tablet={{ col: 4 }}>`. The `Grid` component from `@trussworks/react-uswds` is used with responsive prop syntax like `tablet={{ col: 8 }}` and `mobileLg={{ col: 6 }}`.

14. USWDS utility classes are used inline as `className` strings directly on native HTML elements (not via CSS modules or styled-components). Examples: `className="usa-skipnav"`, `className="usa-overlay"`, `className="usa-prose"`, `className="font-heading-xl margin-top-0 tablet:margin-bottom-0"`.

15. Conditional class application uses template literals: `` className={`usa-overlay ${ mobileNavOpen ? 'is-visible' : '' }`} `` from `Header.js`. Note the spaces inside template literal braces around the expression.

### Aspect 4: State Management

16. All state is managed with React's built-in `useState` hook only - no Redux, Context API, Zustand, MobX, or other external state libraries are used. State lives at the component level closest to where it is needed.

17. State initialization follows the array destructuring pattern with spaces inside brackets: `const [ mobileNavOpen, setMobileNavOpen ] = useState(false)`. Note the spaces inside the destructuring brackets - this is consistent across all state declarations in `Header.js`.

18. State updaters that depend on previous state use the functional form. Example from `Header.js`: `setMobileNavOpen(prevOpen => !prevOpen)` and `setNavDropdownOpen(prevNavDropdownOpen => { ... return newOpenState })`. This pattern is used consistently when the new state depends on the old state.

19. The custom `useFetch` hook in `src/hooks/useFetch.js` manages async data-fetching state with three state variables: `response` (initially `null`), `mode` (initially `MODE_LOADING`), and `error` (initially `null`). It returns `{ response, mode, error, callOnce }`.

### Aspect 5: Props and Data Flow

20. Simple components accept a single `props` parameter without destructuring. Example from `Names.js`: `export default function Names(props)` and then `props.kind` is used inside the function body. There is no `{ kind }` destructuring in the function signature.

21. Props are passed as simple JSX attributes without spreading. Data flows top-down explicitly. In `App.js`, `<Names kind={match.params.kind} />` passes route params as props. There is no prop spreading (`{...props}`) pattern used.

22. Navigation items (primary nav, secondary nav) are built as plain JavaScript arrays of JSX elements defined as `const` variables inside the component function body, then passed to USWDS component props. Example from `Header.js`: `const primaryNavItems = [...]` and `const secondaryNavItems = [...]` passed to `<ExtendedNav primaryItems={primaryNavItems} secondaryItems={secondaryNavItems}>`.

23. Helper render functions accept `(response, mode, err)` as their first three parameters, matching the destructured return of `useFetch`. They receive additional context params after (e.g., `kind` in `renderNames`). These helpers are called inline in JSX: `{ renderFortune(response, mode, err) }` and `{renderNames(response, mode, err, props.kind)}`.

### Aspect 6: Import/Export Patterns

24. React is always imported explicitly at the top of every component file: `import React from 'react'` or `import React, { useState } from 'react'`. This is enforced by the ESLint rule `react/react-in-jsx-scope: 2`. Even though React 17+ allows JSX without importing React, this project requires the explicit import.

25. Named imports from `react` use destructured syntax on the same import line: `import React, { useState } from 'react'` and `import { useEffect, useState } from 'react'`. Hooks are never imported separately.

26. USWDS component imports use named imports with multi-line formatting when more than one component is needed. Example from `Footer.js`:
    ```js
    import {
      Address, Footer, FooterNav, Grid, GridContainer, Logo, SocialLinks
    } from '@trussworks/react-uswds'
    ```
    Example from `Header.js`:
    ```js
    import {
      ExtendedNav,
      Header,
      Menu,
      NavDropDownButton, NavMenuButton,
      Search, Title
    } from '@trussworks/react-uswds'
    ```

27. Local component imports have NO semicolons at the end of the line. Example from `App.js`: `import Footer from './components/Footer'` (no semicolon). This is consistent across all local imports in component files. The ESLint `semi` rule is set to `0` (off), making semicolons optional.

28. Import order follows: (1) React first, (2) third-party libraries (`@trussworks/react-uswds`, `react-router-dom`), (3) local relative imports. Example from `Header.js`: React, then react-uswds, then react-router-dom, then `./Names`.

29. Custom hooks export their mode constants as named exports alongside the default function export. In `useFetch.js`: `export const MODE_LOADING`, `export const MODE_ERROR`, `export const MODE_SUCCESS` are all exported from the same file as `export default function useFetch`. Consumers import the hook and its constants in one statement: `import useFetch, { MODE_ERROR, MODE_LOADING, MODE_SUCCESS } from '../hooks/useFetch'`.

### Aspect 7: Type Definitions and Language Patterns

30. The project uses plain JavaScript (`.js` files) - there is no TypeScript. No `.ts`, `.tsx` files exist anywhere. No PropTypes are used either. There is no runtime type validation.

31. String constants for mode states are SCREAMING_SNAKE_CASE: `MODE_LOADING`, `MODE_ERROR`, `MODE_SUCCESS`. These are exported module-level constants defined with `export const`. Example: `export const MODE_LOADING = 'MODE_LOADING'` - the string value matches the constant name.

32. Object maps/lookup tables are defined as `export const` at module level, not inside functions. Example from `Names.js`: `export const apiMap = { brute: 'Brutethink Words', easy: 'Good for Server Names', ... }`. These are exported so other files can consume them.

33. Template literals are used for string interpolation with spaces inside the curly braces: `` `HTTP error ${ resp.status } - ${ resp.statusText }` `` from `useFetch.js`. Template literal expressions consistently use `` ${ value } `` with a space before and after the expression.

34. Arrow functions are used for inline callbacks and event handlers. Named inner async functions use the `async function` declaration syntax. Example from `useFetch.js`: `async function callOnce(_url, _opts)` defined inside the hook body. Leading underscore prefix is used for inner function parameters to avoid shadowing outer scope variables.

### Aspect 8: Error Handling

35. The `useFetch` hook handles two distinct error scenarios: HTTP errors (non-ok response) and network/system errors (catch block). HTTP errors set the error string to the format `` `HTTP error ${ resp.status } - ${ resp.statusText }` ``. System errors set error to `ex.message`. Both set `mode` to `MODE_ERROR`.

36. Error display in components uses a simple two-paragraph structure inside a `<div>`: `<div><p>Error</p><p>{err}</p></div>`. This is used identically in both `Fortune.js` and `Names.js`. The error message from the hook's `error` field is passed as `err` to the render helper.

37. There is no global error boundary, no toast notification system, no error logging service. Errors are displayed inline where the content would normally render, inside the same grid section as the successful content.

38. The `useFetch` hook checks `if (url)` before making requests in the `useEffect`. This guards against calling fetch with an undefined URL. No URL validation beyond truthiness check.

### Aspect 9: Testing Patterns

39. Tests live in `__tests__/` subdirectories adjacent to the files they test. The only test file is `src/hooks/__tests__/useFetch.test.js` which tests `src/hooks/useFetch.js`.

40. Test files use two section separator comments in the `// ---...---` style (80 dashes) with a heading: `// ----------------------------------------------------------------------------`. Sections are: `// Fixtures` for test data and `// Tests` for the describe block. This separator style is mandatory for test files.

41. Tests use `describe('hooks::useFetch', () => { ... })` with the path-like naming convention `domain::hookName`. For components the pattern would be `components::ComponentName`.

42. Fixtures are defined as `const` variables at module scope outside the describe block, following the `FIXTURE_` prefix convention: `const FIXTURE_URL = 'http://www.example.org'` and `const FIXTURE_PAYLOAD = { returnedData: 'foo' }`.

43. The testing stack uses: `@testing-library/react-hooks` for hook testing (`renderHook`), `react-test-renderer` for `act`, `fetch-mock` for mocking fetch calls, and `whatwg-fetch` as a polyfill. Tests do NOT use `@testing-library/react` (the component testing library) - only the hooks testing library. `enzyme` is installed but not used in the current test.

44. Test setup uses `beforeAll` for global setup (assigning `global.fetch = fetch` and configuring `fetchMock`) and `afterAll` for cleanup (`fetchMock.restore()`). There is no `beforeEach`/`afterEach` cleanup pattern.

45. The Jest configuration in `package.json` collects coverage from `src/**/*.{js,jsx}` but explicitly excludes `src/index.js`. Coverage threshold is not enforced via config - just collected.

### Aspect 10: Form Handling and Validation

46. There are no form components in this project. The only form-like element is the `<Search size="small" onSubmit={handleSearch} />` from USWDS in `Header.js`, where the submit handler simply does `console.log('Search called')`. There is no form validation, no form state management, no controlled inputs pattern implemented.

47. Search and other interactive elements are handled via event handler functions defined as `const` arrow functions inside the component body: `const handleSearch = () => { console.log('Search called') }`. Handler naming follows the `handle` + EventName pattern: `handleToggleNavDropdown`, `handleSearch`.

48. Toggle handlers that manage boolean arrays use a functional update pattern creating new arrays: `const newOpenState = Array(prevNavDropdownOpen.length).fill(false)` then `newOpenState[index] = !prevNavDropdownOpen[index]`. Never mutate state arrays directly.

### Aspect 11: Data Fetching and API Integration

49. All data fetching goes through the single `useFetch` custom hook located at `src/hooks/useFetch.js`. Components never call `fetch` directly. The hook is the only abstraction layer between components and the network.

50. API URLs are injected as global constants via `webpack.DefinePlugin` in `webpack.config.js`. The constants `URL_FORTUNES` and `URL_NAMES` are available as bare global identifiers in component code: `useFetch(URL_FORTUNES)` and `useFetch(URL_NAMES + props.kind)`. ESLint suppression is required: `// eslint-disable-next-line no-undef` must appear on the line before any usage of these injected globals.

51. URL construction for parameterized endpoints uses simple string concatenation: `URL_NAMES + props.kind`. No URL builder utility, no template literals, no path joining library.

52. The `useFetch` hook exposes `callOnce` as part of its return value to support imperative/programmatic refetch calls (used in tests). Default usage in components only uses the destructured `{ response, mode, err }` (note: the hook actually returns `error` not `err` - components alias it by naming in destructuring or pass it directly to render helpers).

53. Data fetching is triggered automatically on mount via `useEffect` with `[url, opts]` as dependencies. The hook conditionally fires: `if (url) { callOnce(url, opts) }`. No refetch on parameter change beyond the URL dependency in useEffect.

### Aspect 12: Routing and Navigation Integration

54. Routing uses `react-router-dom` v5 with `HashRouter` (not `BrowserRouter`). The router is named `Router` via import alias: `import { HashRouter as Router, ... } from 'react-router-dom'`. All routes are hash-based (`/#/names`, `/#/`).

55. Routes are defined in `App.js` using `<Switch>` and `<Route>`. Each route renders a dedicated sub-component or component directly as children of `<Route>`: `<Route path="/names"><NamesRoute /></Route>`. The catch-all default route is `<Route path="/">`.

56. Route parameter extraction uses `useRouteMatch` hook, not `useParams`. Example: `const match = useRouteMatch('/names/:kind')` then `match.params.kind`. The route-specific logic is wrapped in a separate function component (`NamesRoute`) defined at the bottom of `App.js` rather than inline in the Route.

57. Navigation links inside nav menus use `react-router-dom`'s `<Link>` component: `<Link to={'/names/' + k}>`. Plain `<a href>` elements are used for external links and placeholder links.

58. The app layout structure is: `<Router>` wraps skip-nav link, `<Header />`, `<main id="main-content">` containing `<Switch>` routes, and `<Footer />`. The `id="main-content"` on `<main>` matches the skip-nav anchor href `#main-content` for accessibility.

### Aspect 13: Permissions and Security Patterns

59. There is no authentication or authorization system in this project. No login, no session management, no JWT tokens, no protected routes, no user roles or permissions system. This is a public demo scaffolding app.

60. No sensitive data handling patterns exist. No environment variable exposure patterns beyond build-time URL injection. The webpack `DefinePlugin` substitutes environment variables at build time, so they are compiled into the bundle - not runtime secrets.

### Aspect 14: Performance Optimization Patterns

61. There is no explicit performance optimization in this project. No `React.memo`, no `useMemo`, no `useCallback`, no code splitting, no lazy loading, no virtualization. Components re-render on any state change.

62. The `useEffect` in `useFetch` has `[url, opts]` as its dependency array, which means the fetch re-runs whenever the URL or opts reference changes. The `opts` object should be stable (memoized or constant) to prevent infinite re-fetch loops, but this is not enforced in the codebase.

63. Webpack is configured in `mode: "development"` only. There is no production webpack configuration with minification, tree-shaking optimization, bundle splitting, or content-hash filenames.

### Aspect 15: Configuration Management

64. Build-time configuration is managed exclusively via `webpack.DefinePlugin` in `webpack.config.js`. Environment variables `URL_FORTUNES` and `URL_NAMES` are read from `process.env` at build time with fallback defaults to production API URLs. Pattern: `process.env.URL_FORTUNES ? process.env.URL_FORTUNES : 'https://api.esotericsoftware.com/v1/fortunes/'`.

65. The project uses Node v14 as specified in `.nvmrc` (referenced in `Front_End_Development.md`). The babel config in `.babelrc` targets `@babel/preset-env` and `@babel/preset-react` without explicit browserslist configuration.

66. ESLint configuration lives in `.eslintrc` (YAML format, not JSON), not inside `package.json`. The `eslintConfig` field in `package.json` references `react-app` extends but is superseded by the standalone `.eslintrc` file which has `root: true`.

### Aspect 16: Documentation Patterns

67. Section separator comments use the 80-dash style: `// ----------------------------------------------------------------------------`. These are used in test files to delineate sections. The comment is exactly 80 characters wide (the double-slash plus 78 dashes). This same style should be used in any new files that have logical sections.

68. ESLint disable comments are used inline with specific rule names on the line immediately before the problematic code: `// eslint-disable-next-line no-undef`. Never use file-level disables. Always disable the specific rule only.

69. There are no JSDoc comments in any source files. No `@param`, `@returns`, `@typedef` documentation. Code is self-documenting through naming.

70. The `Front_End_Development.md` file in `services/` documents: prerequisites (Node v14), environment variables (with table format), build commands, run commands, code quality tools, and test runner. New features should be documented in this file using the same markdown table format for environment variables.

### Aspect 17: Build and Tooling

71. Build tooling is Webpack 5 (not Vite, Parcel, or create-react-app). The webpack config at `services/ui/webpack.config.js` uses CommonJS `module.exports` format. Webpack plugins used: `ESLintPlugin` (for lint-on-build), `HtmlWebPackPlugin` (for HTML template), and `webpack.DefinePlugin` (for env var injection).

72. Asset handling is configured in webpack with separate loaders: `babel-loader` for `.js` files, `style-loader` + `css-loader` for `.css` files, `file-loader` for fonts (`woff`, `woff2`, `ttf`, `eot`, `svg`) outputting to `fonts/`, and `file-loader` for `.png` images outputting to `images/`.

73. The npm scripts are: `start` (webpack serve), `build` (webpack), `lint` (eslint --ext .js --fix src/), `test` (jest --coverage), `test-flow` (jest --coverage --watch). The `lint` command auto-fixes violations. Run `lint` before committing.

74. Jest test configuration in `package.json` uses `moduleNameMapper` to stub out non-JS assets: binary files map to `src/__mocks__/fileMock.js` (returns string `'test-file-stub'`) and CSS files map to `src/__mocks__/styleMock.js` (returns empty object `{}`). Test environment is the default jsdom.

75. Babel is configured via `.babelrc` (not `babel.config.js`) with presets `@babel/preset-env` and `@babel/preset-react`, and plugins `@babel/plugin-proposal-class-properties` and `@babel/plugin-transform-runtime`. This same babel config is used for both webpack bundling and jest transpilation.

### Aspect 5 (Accessibility Patterns - mapped as additional rules):

76. The app includes a skip navigation link as the first focusable element: `<a className="usa-skipnav" href="#main-content">Skip to main content</a>` in `App.js`. This must be placed before `<Header />` in every page layout.

77. Navigation elements use `aria-label` attributes on landmark components. Example: `<ExtendedNav aria-label="Primary navigation">` and `<FooterNav aria-label="Footer navigation">`. USWDS component `aria-label` props should always be set on nav elements.

78. The HTML `<html lang="en">` attribute is set in `src/index.html`. The document title is set in `<title>HOOP</title>`. Every `<a>` element that serves as a logo link includes both `title` and `aria-label` attributes: `<a href="/" title="Home" aria-label="Home">`.

79. React `<React.StrictMode>` wraps the entire app in `src/index.js`. This enables additional runtime warnings for deprecated patterns. All new code must be compatible with StrictMode (no deprecated lifecycle methods, no findDOMNode usage, etc.).
