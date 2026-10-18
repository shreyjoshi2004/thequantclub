import { Controller } from "@hotwired/stimulus"
import { forceSimulation, forceLink, forceManyBody, forceCenter } from "d3-force"
import { select } from "d3-selection"

export default class extends Controller {
  static values = { url: String }

  async connect() {
    const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
    const { nodes, edges } = await response.json()
    this.render(nodes, edges)
  }

  render(nodes, edges) {
    const width = this.element.clientWidth || 800
    const height = 600

    const svg = select(this.element)
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("class", "wiki-graph-svg")

    const simulation = forceSimulation(nodes)
      .force("link", forceLink(edges).id((d) => d.id).distance(90))
      .force("charge", forceManyBody().strength(-220))
      .force("center", forceCenter(width / 2, height / 2))
      .stop()

    for (let i = 0; i < 300; i += 1) simulation.tick()

    svg.append("g")
      .attr("class", "wiki-graph-edges")
      .selectAll("line")
      .data(edges)
      .join("line")
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y)

    const nodeGroup = svg.append("g")
      .attr("class", "wiki-graph-nodes")
      .selectAll("g")
      .data(nodes)
      .join("g")
      .attr("class", (d) => `wiki-graph-node${d.stub ? " wiki-graph-node--stub" : ""}`)
      .attr("transform", (d) => `translate(${d.x}, ${d.y})`)
      .style("cursor", "pointer")
      .on("click", (_event, d) => { window.location.href = `/wiki/${d.slug}` })

    nodeGroup.append("circle").attr("r", 8)
    nodeGroup.append("text").attr("dy", -12).attr("text-anchor", "middle").text((d) => d.title)
  }
}
