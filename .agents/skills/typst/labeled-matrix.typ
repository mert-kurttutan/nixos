// A table keeps row labels, column labels, entries, and brackets on one grid.
#let labeled-matrix(row-labels, column-labels, entries, prefix: none) = {
  assert(row-labels.len() == entries.len())
  for row in entries {
    assert(row.len() == column-labels.len())
  }

  let matrix-bracket(side) = table.cell(
    rowspan: row-labels.len(),
    inset: 0pt,
    stroke: if side == "left" {
      (left: 0.5pt, top: 0.5pt, bottom: 0.5pt)
    } else {
      (right: 0.5pt, top: 0.5pt, bottom: 0.5pt)
    },
    [],
  )

  let body = ()
  for (index, row) in entries.enumerate() {
    if index == 0 and prefix != none {
      body.push(table.cell(rowspan: row-labels.len(), inset: (right: 6pt), prefix))
    }
    body.push(row-labels.at(index))
    if index == 0 { body.push(matrix-bracket("left")) }
    body += row
    if index == 0 { body.push(matrix-bracket("right")) }
  }

  let widths = (auto, 3pt, ..(auto,) * column-labels.len(), 3pt)
  let headings = ([], [], ..column-labels, [])
  if prefix != none {
    widths = (auto, ..widths)
    headings = ([], ..headings)
  }
  table(
    columns: widths,
    align: center + horizon,
    stroke: none,
    inset: (x: 2pt, y: 1.5pt),
    ..headings,
    ..body,
  )
}
