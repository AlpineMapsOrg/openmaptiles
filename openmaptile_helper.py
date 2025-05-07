#!/bin/python

import yaml


all_layers = [
"layers/transportation/",
"layers/boundary/",
"layers/water/",
"layers/waterway/",
"layers/landcover/",
"layers/landuse/",
"layers/park/",
"layers/aeroway/",
"layers/building/"]

# max zoom level we want to generate custom tables
max_zoom = 17


def generated_simplified_mapping(layer):

	with open(layer + "mapping.yaml") as f:
		try:
			mapping = yaml.safe_load(f)
		except yaml.YAMLError as e:
			print(e)
			return

	generated_tables = {"generated":{}, "overwritten":{}}

	if("generalized_tables" not in mapping):
		print(layer, "does not have generalized_tables")
		return


	# find the _gen tables with the highest zoom
	highest_gen_tables = {}
	for table in mapping["generalized_tables"]:
		if("_gen_z" in table):
			zoom = int(table[table.index("_gen_z")+6:])
			name = table[:table.index("_gen_z")]

			tolerance = int( mapping["generalized_tables"][table]["tolerance"][4:])

			if(tolerance != zoom):
				print("tolerance changed", table)
				new_mapping = dict(mapping["generalized_tables"][table])
				new_mapping["tolerance"] = "ZRES" + str(zoom)

				generated_tables["overwritten"] = new_mapping


			if(name not in highest_gen_tables or highest_gen_tables[name][0] < zoom):
				highest_gen_tables[name] = (zoom, mapping["generalized_tables"][table])


	for entry in highest_gen_tables:

		z = highest_gen_tables[entry][0];

		if(z < max_zoom):
			for gen_z in range(z+1, max_zoom+1):

				new_mapping = dict(highest_gen_tables[entry][1])
				new_mapping["tolerance"] = "ZRES" + str(gen_z)

				# print(new_mapping)

				# mapping["generalized_tables"][entry + "_gen_z" + str(gen_z)] = new_mapping
				generated_tables["generated"][entry + "_gen_z" + str(gen_z)] = new_mapping


	if(len(generated_tables["generated"]) != 0 or len(generated_tables["overwritten"]) != 0):
		print(layer)
		#write out 
		with open(layer + "mapping.generated.yaml", 'w') as f:
			#width makes sure that there arent any line breaks in the yaml (not 100 percent sure if line breaks work so setting it high to avoid them)
			yaml.dump(generated_tables, f, default_flow_style=False, width=5000)


if __name__ == '__main__':

	for layer in all_layers:
		generated_simplified_mapping(layer)