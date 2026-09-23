/*

import ZoomableTreemap from "./zoomable_treemap";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("treemap-container");
  if (container) {
    new ZoomableTreemap(container.dataset.src, container);
  }
});

*/


import * as d3 from "d3";

// Specify the chart’s dimensions.
const width = 928;
const height = 924;

// Create the scales.
const x = d3.scaleLinear().rangeRound([0, width]);
const y = d3.scaleLinear().rangeRound([0, height]);

const format = d3.format(",d");
const name = d => d.ancestors().reverse().map(d => d.data.name).join("/");

function position(group, root) {
  group.selectAll("g")
    .attr("transform", d => d === root ? `translate(0,-30)` : `translate(${x(d.x0)},${y(d.y0)})`)
    .select("rect")
    .attr("width", d => d === root ? width : x(d.x1) - x(d.x0))
    .attr("height", d => d === root ? 30 : y(d.y1) - y(d.y0));
}

export default class ZoomableTreemap {
  constructor(src, container) {
    this.src = src;
    this.container = container;

    // Create the SVG container.
    this.svg = d3.create("svg")
      .attr("viewBox", [0.5, -30.5, width, height + 30])
      .attr("width", width)
      .attr("height", height + 30)
      .attr("style", "max-width: 100%; height: auto;")
      .style("font", "10px sans-serif");

    this.data = d3.json(this.src).then(data => {
      // Compute the layout.
      const hierarchy = d3.hierarchy(data)
        .sum(d => d.value)
        .sort((a, b) => b.value - a.value);
      const root = d3.treemap().tile(this.tile).size([width, height])(hierarchy);

      // Display the root.
      let group = this.svg.append("g")
        .call(this.render, root);

      // Append the SVG element to the container.
      this.container.appendChild(this.svg.node());
    });
  }

  // This custom tiling function adapts the built-in binary tiling function
  // for the appropriate aspect ratio when the treemap is zoomed-in.
  tile(node, x0, y0, x1, y1) {
    d3.treemapBinary(node, 0, 0, width, height);
    for (const child of node.children) {
      child.x0 = x0 + child.x0 / width * (x1 - x0);
      child.x1 = x0 + child.x1 / width * (x1 - x0);
      child.y0 = y0 + child.y0 / height * (y1 - y0);
      child.y1 = y0 + child.y1 / height * (y1 - y0);
    }
  }

  render(group, root) {
    const node = group
      .selectAll("g")
      .data(root.children.concat(root))
      .join("g");

    node.filter(d => d === root ? d.parent : d.children)
      .attr("cursor", "pointer")
      .on("click", (event, d) => d === root ? this.zoomout(root) : this.zoomin(d));

    node.append("title")
      .text(d => `${name(d)}\n${format(d.value)}`);

    node.append("rect")
      .attr("id", d => (d.leafUid = crypto.randomUUID("leaf")).id)
      .attr("fill", d => d === root ? "#fff" : d.children ? "#ccc" : "#ddd")
      .attr("stroke", "#fff");

    node.append("clipPath")
      .attr("id", d => (d.clipUid = crypto.randomUUID("clip")).id)
      .append("use")
      .attr("xlink:href", d => d.leafUid.href);

    node.append("text")
      .attr("clip-path", d => d.clipUid)
      .attr("font-weight", d => d === root ? "bold" : null)
      .selectAll("tspan")
      .data(d => (d === root ? name(d) : d.data.name).split(/(?=[A-Z][^A-Z])/g).concat(format(d.value)))
      .join("tspan")
      .attr("x", 3)
      .attr("y", (d, i, nodes) => `${(i === nodes.length - 1) * 0.3 + 1.1 + i * 0.9}em`)
      .attr("fill-opacity", (d, i, nodes) => i === nodes.length - 1 ? 0.7 : null)
      .attr("font-weight", (d, i, nodes) => i === nodes.length - 1 ? "normal" : null)
      .text(d => d);

    group.call(position, root);
  }

  // When zooming in, draw the new nodes on top, and fade them in.
  zoomin(d) {
    const group0 = this.group.attr("pointer-events", "none");
    const group1 = this.group = this.svg.append("g").call(this.render, d);
  
    x.domain([d.x0, d.x1]);
    y.domain([d.y0, d.y1]);
  
    this.svg.transition()
      .duration(750)
      .call(t => group0.transition(t).remove()
        .call(position, d.parent))
      .call(t => group1.transition(t)
        .attrTween("opacity", () => d3.interpolate(0, 1))
        .call(position, d));
  }

  // When zooming out, draw the old nodes on top, and fade them out.
  zoomout(d) {
    const group0 = this.group.attr("pointer-events", "none");
    const group1 = this.group = this.svg.insert("g", "*").call(this.render, d.parent);

    x.domain([d.parent.x0, d.parent.x1]);
    y.domain([d.parent.y0, d.parent.y1]);

    this.svg.transition()
      .duration(750)
      .call(t => group0.transition(t).remove()
        .attrTween("opacity", () => d3.interpolate(1, 0))
        .call(position, d))
      .call(t => group1.transition(t)
        .call(position, d.parent));
  }
}