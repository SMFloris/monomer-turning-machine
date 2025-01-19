# Monomer Turning Machine

Based on the paper `Turning Machines: a simple algorithmic model` by: W. Lui and Ashutosh Saxena.

The program randomly generates monomer chains. Blocking rule is partially modified from the one in the paper.

## Concepts

1. Monomer

A monomer is a small molecule that can be chemically bonded to other identical or similar molecules to form a larger structure called a polymer.

2. Turning machine

A turning machine is a monomer configuration (chain) that can 'turn' a certain chain based on a set of specific rules.
In this case, I randomly assign a state to each monomer and then turn each monomer by 60 degrees until the state is 0.

## Features

![printscreen](resources/monomer.png?raw=true "Monomer Turning Machine")

### Instant / Step mode

You can choose between instant and step modes. The instant mode will just show you the final configuration, while the step mode will show you the configuration turn-by-turn, allowing you to undeerstand how the final configuration is formed.

![printscreen_instant](resources/monomer_instant.png?raw=true "Monomer Turning Machine - Instant Mode")

### Line / Monomer mode

When in line mode, you'll be able to see the chain interpolated via the Catmull-Rom algorithm.
In Monomer mode, you can see the states of each monomer.

![printscreen_instant](resources/monomer_line.png?raw=true "Monomer Turning Machine - Line Mode")

# Paper link:
[Turning Machines: a simple algorithmic model for molecular robotics](https://arxiv.org/pdf/2009.00755)
