# Snapshots

- `Reference/`: approved pictures. Tests fail when a render differs from its
  reference by more than 0.5% of pixels.
- `Output/` (not committed): what the latest test run rendered. CI publishes it
  to the `snapshots` branch.

To approve a new or changed picture, copy it from the `snapshots` branch into
`Reference/` with the same name. Names start with the version that introduced
them (`v0.1-…`); never change an existing reference unless the change is
intended.
