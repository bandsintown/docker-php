#!/usr/bin/env bash
# Originally from CircleCi's `gen-dockerfiles.sh`
# https://github.com/CircleCI-Public/cimg-shared/blob/30bfff7494c192d12364b5658089fad9d3d0e78d/gen-dockerfiles.sh

# This script generates Dockerfiles for a given set of versions and variants.
# It looks for a `Dockerfile.template` file in the root of the repository and
# an optional `variant.Dockerfile.template` in the `variants` directory.
# Then it creates the Dockerfiles in the `versions/[VERSION]` and
# `versions/[VERSION]/[VARIANT]` directories.

# A Docker image is a combination of REGISTRY/NAMESPACE/REPOSITORY[:TAG].
# Import image information
source ./manifest

export CREATE_VERSIONS=("$@")

# A version can be a major.minor or major.minor.patch version string.
# Additionally versions/version groups are separated by spaces.
#
# Examples:
#
# 1.13.1 v1.14.2
# v20.04
#
# Template variables exists in the `Dockerfile.template` files. The start and
# end with two percent symbles `%%`. During Dockerfile generation, they get
# replaced with actual valuables. Here's what's available to use:
#
# %%VERSION_FULL%% - the complete version passed to the script such as `1.2.3`
# %%VERSION_MAJOR%% - just the major integer of the version such as `1`
# %%VERSION_MINOR%% - the major and minor integers of the version with a decimal in the middle such as `1.2`
# %%ALIAS1%% - what's passed as the alias when passing version strings to the build script (see above)
# %%PARAM1%% - what's passed as the paramater when passing version strings to the build script (see above)

#####
# Helper functions.
#####

# Parses all template variables, regardless of if it's a main or variant image
parse_template_variables () {

	local variantPath=${1}
	local parent=${2}
	local fileTemplate=${3}
	local parentTag=${4}
	local directory=${5}

	[[ -d "versions/$directory" ]] || mkdir "versions/$directory"

	sed -e 's!%%PARENT%%!'"${parent}"'!g' "${fileTemplate}" > "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's/%%PARENT_TAG%%/'"${parentTag}"'/g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's/%%NAMESPACE%%/'"${namespace}"'/g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's/%%VERSION_FULL%%/'"${vgVersionFull}"'/g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's/%%VERSION_MINOR%%/'"${vgVersionMinor}"'/g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's/%%VERSION_MAJOR%%/'"${vgVersionMajor}"'/g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's!%%PARAM1%%!'"${vgParam1}"'!g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
	sed -i.bak 's!%%ALIAS1%%!'"${vgAlias1}"'!g' "./versions/${vgVersionFull}/${variantPath}Dockerfile"
}

filepath_templating () {
	if [[ -f "./variants/${variant}.Dockerfile.template" ]]; then
		fileTemplate="./variants/${variant}.Dockerfile.template"
	else
		echo "Error: Variant ${variant} doesn't exist. Exiting."
		exit 2
	fi
}

#####
# Starting version loop.
#####
for versionGroup in "$@"; do

	# Process the version group(s) that were passed to this script.
	if [[ "$versionGroup" == *"#"* ]]; then
		vgParam1=$(cut -d "#" -f2- <<< "$versionGroup")
		versionGroup="${versionGroup//$vgParam1}"
		versionGroup="${versionGroup//\#}"
	fi

	if [[ "$versionGroup" == *"="* ]]; then
		vgAlias1=$(cut -d "=" -f2- <<< "$versionGroup")
		versionGroup="${versionGroup//$vgAlias1}"
		versionGroup="${versionGroup//=}"
	fi

	vgVersionFull=$(cut -d "v" -f2- <<< "$versionGroup")

	if [[ $vgVersionFull =~ ^[0-9]+\.[0-9]+ ]]; then
		vgVersionMinor=${BASH_REMATCH[0]}
	else
		echo "Version matching (minor) failed." >&2
		exit 1
	fi

	if [[ $vgVersionFull =~ ^[0-9]+ ]]; then
		vgVersionMajor=${BASH_REMATCH[0]}
	else
		echo "Version matching (major) failed." >&2
		exit 1
	fi

	[[ -d "versions/$vgVersionFull" ]] || mkdir "versions/$vgVersionFull"

	# no parentTag loop; creates Dockerfiles and variants
	if [[ -z "${parentTags[0]}" ]]; then
		parse_template_variables "" "$parent" "./Dockerfile.template" "$vgVersionFull" "$vgVersionFull"

		for variant in "${variants[@]}"; do
			filepath_templating
			parse_template_variables "$variant/" "$repository" "$fileTemplate" "$vgVersionFull" "$vgVersionFull/$variant"
		done
	else

	# parentTag loop; one Dockerfile will be created along with however many variants there are for each parentTag
		for parentTag in "${parentTags[@]}"; do
			if [[ -n $parentTag ]]; then
				parse_template_variables "$parentTag/" "$parent" "./Dockerfile.template" "$parentTag" "$vgVersionFull/$parentTag"

				for variant in "${variants[@]}"; do
					filepath_templating
					parse_template_variables "$parentTag/$variant/" "$repository" "$fileTemplate" "$vgVersionFull-$parentSlug-$parentTag" "$vgVersionFull/$parentTag/$variant"
				done
			fi
		done
	fi

	# This .bak thing fixes a Linux/macOS compatibility issue, but the files are cleaned up
	find . -name \*.bak -type f -delete
done
