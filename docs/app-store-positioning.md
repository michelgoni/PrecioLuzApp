# App Store Positioning

## Goal

Define a commercial positioning baseline for `PrecioLuzApp` before preparing App Store metadata, screenshots, paywall copy, or future monetization decisions.

The app should be positioned as a domestic decision tool, not as a simple electricity price table.

## Core positioning

`PrecioLuzApp` helps people in Spain decide when it is worth using electricity during the day, using hourly prices, fast visual reading, and local alerts.

### Positioning statement

> Check hourly electricity prices, find the best hours of the day, and receive useful alerts before you consume.

### Product promise

> Understand electricity prices in seconds and make better decisions about when to use your appliances.

### Key message

The product is not only about seeing prices. It is about turning hourly data into simple decisions:

- now is a good time;
- better wait;
- this is the cheap slot;
- avoid this expensive slot;
- enable an alert and stop checking manually.

## Target audience

### Primary user

People in Spain with PVPC, indexed electricity tariffs, or high sensitivity to hourly electricity prices.

Needs:

- check the current price quickly;
- find cheap hours without reading dense tables;
- receive alerts before the best or worst hours;
- estimate how much using an appliance could cost;
- avoid complex setup, accounts, or external systems.

### Main use cases

| Use case | User need | App response |
|---|---|---|
| Run a washing machine | Know whether to run it now or later | Current price + cheap hours |
| Cook or use high-consumption appliances | Avoid an expensive time slot | Hourly list + daily maximum |
| Plan daily usage | Find an available cheap period | Daypart chart |
| Daily monitoring | Avoid checking the app every hour | Local notifications |
| Estimate cost | Understand approximate usage impact | Appliance cost calculator |

## Value proposition

### Functional value

- Spanish hourly electricity prices.
- Daily summary: current, average, minimum, and maximum.
- Hourly traffic-light semantics for cheap, mid-range, and expensive slots.
- Daily chart split by dayparts.
- Estimated appliance cost calculation.
- Configurable local alerts.

### Emotional value

- Less uncertainty.
- More control over domestic electricity usage.
- Less dependency on websites or dense tables.
- A clearer sense of making better decisions with little effort.

### Differentiation

- Native iPhone experience.
- No account in the base scope.
- No own backend in the base scope.
- Dark visual direction and fast reading.
- Local alerts focused on utility, not artificial engagement.

## App Store messaging

### Name

Current development name:

```text
PrecioLuzApp
```

It is clear for development, but a more natural commercial name could be evaluated before release.

Possible names:

- `Precio Luz`
- `Precio Luz España`
- `Luz Horaria`
- `Luz Hoy`
- `Ahorra Luz`

Criterion: prioritize ASO clarity over originality.

### Subtitle candidates

- `Electricity prices and alerts`
- `Find today’s cheapest hours`
- `Decide when to use electricity`
- `PVPC prices, charts, and alerts`
- `Smarter electricity timing`

### Promotional text

```text
Check hourly electricity prices in Spain, find the cheapest hours, and receive alerts to decide better when to use electricity.
```

### Short description

```text
PrecioLuzApp helps you understand hourly electricity prices in Spain. Check the current price, find the cheapest hours of the day, review the daily curve by time segment, and enable local alerts for daily minimums, maximums, or custom thresholds.
```

### Extended description

```text
PrecioLuzApp turns hourly electricity prices into a simple decision.

See at a glance how much electricity costs right now, what the daily minimum and maximum are, and which hours are more convenient for using your appliances.

The app shows a clear hourly list, a daily chart by time segment, and an estimated appliance cost calculator to help you understand the impact of using electricity at a specific hour.

You can also enable local alerts before the best or worst slots, without creating an account and without relying on remote push notifications.
```

## ASO keywords

> Pending real validation in App Store Connect and competitive analysis.

Initial keyword ideas:

```text
electricity price, hourly electricity, PVPC, Spain electricity, electricity alerts, cheap electricity, electricity tariff, energy savings, light price, power price
```

Spanish-market metadata should also evaluate localized keywords such as:

```text
precio luz, luz hoy, PVPC, electricidad, tarifa luz, luz barata, precio electricidad, ahorro luz, hora barata, factura luz
```

Avoid claims the app cannot support, such as `guaranteed savings`, `reduce your bill`, or `real appliance consumption`, unless the corresponding functionality and evidence exist.

## Recommended screenshots

### Screenshot 1 — Immediate decision

Message:

```text
Know whether now is a good time to consume
```

Screen: `Prices` tab with current price, minimum, maximum, and hourly traffic-light semantics.

### Screenshot 2 — Cheapest hours

Message:

```text
Find the cheapest hours without reading tables
```

Screen: hourly list with cheap, mid-range, and expensive classification.

### Screenshot 3 — Daily curve

Message:

```text
Compare morning, afternoon, and night at a glance
```

Screen: `Chart` tab with daypart picker.

### Screenshot 4 — Estimated cost

Message:

```text
Estimate how much an appliance could cost
```

Screen: calculation sheet.

### Screenshot 5 — Local alerts

Message:

```text
Get alerts before the best or worst hours
```

Screen: notification settings.

## Monetization recommendation

### Initial model

`Freemium` with a possible one-time Pro unlock.

The app should not charge for simple access to hourly price data, because that data is perceived as public and replaceable.

Paid value should be associated with:

- personalization;
- automation;
- better estimates;
- extended history;
- widgets;
- smart alerts;
- appliance profiles.

### Free tier

- Current price.
- Daily summary.
- Hourly list.
- Basic chart.
- Basic estimated cost calculation.
- Limited essential alerts.

### Pro tier

- Unlimited smart alerts.
- Custom appliance profiles.
- Energy-per-cycle values from energy labels.
- Multi-hour cost calculation.
- Extended history.
- Advanced widgets.
- Weekly or monthly comparisons.

## Precision and claims

### Safe claims

- `hourly electricity prices`;
- `estimated cost`;
- `local alerts`;
- `helps you decide`;
- `find cheap hours`.

### Claims to avoid

- `real consumption` without external measurement;
- `guaranteed savings`;
- `automatically reduces your bill`;
- `exact appliance consumption`;
- `intelligent energy optimization` if the app only uses simple deterministic rules.

### Recommended calculation copy

```text
The displayed cost is an estimate based on hourly price, configured power or energy usage, and duration. Real consumption may vary depending on model, program, load, and usage conditions.
```

## Positioning roadmap

### Commercial MVP

- README and App Store metadata focused on decision-making.
- Commercial screenshots.
- Simple onboarding.
- Clear notification copy.
- Estimation disclaimer.

### Initial Pro layer

- Custom appliance profiles.
- Energy-per-cycle values from energy labels.
- More alerts.
- Widgets.

### Advanced evolution

- Energy label scanning.
- Appliance model catalog.
- Integration with compatible meters.
- Home Assistant.
- Estimated savings analysis.

## Communication principle

Always communicate `making better decisions`, not `guaranteed savings`.

The app should convey clarity, control, and speed:

> open, read, decide.
