# Najet101.github.io

Switch Grass Model

The model encompasses the following entities: 
1.	Agents 
•	Farmers: There are the main actors of this model. The strength of this modeling framework is the explicit use of spatially variable data, which cannot be accurately represented with at traditional LCA approach. Here, each farmer possesses various individual characteristics (e.g., age, land size, familiarity, risk aversion, etc.) that will affect their decision-making. 
•	Refineries (Fuel Plants): Biofuel refineries process switchgrass into ethanol, which is used as a substitute for gasoline in the transportation sector. Currently, first generation bio-refineries process corn sugars into ethanol. Second generation “advanced cellulosic” refineries have been proven in concept but have not been established on a commercial scale. The switchgrass biofuel supply chain analyzed in our case study uses these second-generation cellulosic refineries. Each refinery agent in the case study has its own operating parameters much like each farmer agent has its own growing conditions. Conversion rates (liters of fuel per tonne of switchgrass), process energy intensity, and location are all factors that vary among refineries. These values need to be set before importing the refineries into the scenario modeler.
•	Co-fired Generation Plants (Electric Plants): Another agent type for the switchgrass case study is co-fired generation plant. These electricity-generating utility plants can burn dry switchgrass to heat water in a typical Rankine power cycle. Typically biomass is used to supplement a more energy dense fuel such as coal. The percentage of biomass to total fuel mass is called the co-fired percentage. Typical co-fired percentages are around 6%. The scenario modeler will analyze the emissions associated with burning biomass to produce electricity and will compare it to the fuel that it is replacing in the generation plants. Values such as heat rate, parasitic energy loss, and geographic location are set for each generation plant agent before running the scenario modeler.

2.	Patches
They represent the agricultural parcel owned by the farmers. Each patch is a parcel. Farmers can decide to increase or decrease the amount of land they devote to switchgrass at each time step.

A farm agent has its own state, which is updated after every simulation period of one. The state of the farm agent includes personal characteristics and potential gain from planting switchgrass. The important parameters with respect to the individual characteristics of the farmers are detailed below.


Symbiosis Model

The model encompasses the following entities: 
1.	Agents: They are the plants, represented by plant managers. In this model, 47 plants had been selected, 11 of them being already involved in a local symbiosis endeavor, the main activities are: sugar refinery, cereals and oil-seed grains agricultural cooperative, pulp and paper mills, plastics factories, cement plants, and biochemical transformation plants (Error! Reference source not found. and Error! Reference source not found.)
2.	Patches: They are the cells where the plants are located, each plant releases CO2 on the patch underneath it.
3.	Links between agents that represent the exchange of materials: if materials (inputs and outputs) are available. Links will be created between the plants. This model uses actual quantitative input data to represent the symbiosis development, Error! Reference source not found. summarizes the input and output flows for each participating plant.
4.	GIS layers: Currently used as the geographic display of the roads, and the location of the plant. The plants use truck to exchange material with each other, in this model CO2 emissions from transportation is calculated using the distance between travelled during the delivery stage. 
