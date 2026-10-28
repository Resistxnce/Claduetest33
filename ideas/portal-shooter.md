# Portal shooter (Roblox)

Game idea, parked here for later. Nothing is built yet.

## Pitch

A Roblox shooter where every player carries a portal gun next to their
weapon. You place two linked portals and shoot, move and dodge through them:
flank through a wall, fire down a corridor from across the map, or drop a
portal under someone to send them somewhere else.

## Core loop

- Primary weapon for damage, portal gun on a second slot (blue and orange
  shots, like Portal).
- Each player has their own pair; placing a third portal replaces the oldest.
- Bullets, players and thrown items pass through portals and keep their speed.
- Rounds are short team deathmatch or free-for-all on small maps built for
  portal tricks.

## Ideas to try

- Only some surfaces take portals (a white panel material), so maps can
  control where shortcuts go.
- Portals close after a few seconds, or after taking a few hits.
- Enemies can see your portals' outline so a portal camp can be countered.
- Modes: capture the flag where the flag can't go through portals; a
  "one portal pair per team" mode.
- Cosmetics: portal colours and edge effects as unlockable skins.

## Open questions

- How to render the view through a portal in Roblox (ViewportFrame with a
  cloned scene, or a camera trick) and keep it fast on mobile.
- Server-side hit checks for shots that pass through portals.
- Keeping momentum feeling right with Roblox character physics.
