This folder should follow the following structure:

plants /
  plantname /              <-- use the same name as the enum, not the defined "prettyName" attribute
    dropdown_icon.png      <-- this would be totally fine being the same picture as the last (fully grown) icon
    1.png
    2.png
    (and so on)


Once sketches are done, set the num_drawings field in the PlantKind class in plant.dart! This way it should be 
simpler to implement the garden.