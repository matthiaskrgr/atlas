#!/bin/bash

#    atlas script - tries to bruteforce good texture atlas resolutions
#    Copyright (C) 2013  Matthias Krüger

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 1, or (at your option)
#    any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA


make_atlas_check=`whereis make_atlas | wc -w`

if [ "${make_atlas_check}" == "1" ]; then
	echo "ERROR: make_atlas cannot be found."
	exit 1
fi

if [ -f GLOBAL_LOG ] ; then
	rm GLOBAL_LOG
fi

NC='\e[0m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
TEAL='\e[1;36m'

inputfiles2=`find . | awk /\.png$/ | sed -e /atlas/d -e s/\.\/./`
echo  ${inputfiles2} > /dev/null

gen_atlas() {

#set -x
inputfiles=`find . | awk /\.png$/ | sed -e /atlas/d -e s/\.\/./`
printf "gathering file information..."
#echo "$inputfiles" >& /dev/null
inputfileamount=`echo $inputfiles | wc -w`


sizesXmax=`identify ${inputfiles} | awk '{print $3}' | tr "x" " " | awk '{print $1}' | sort -n | tail -1`
sizesYmax=`identify ${inputfiles} | awk '{print $3}' | tr "x" " " | awk '{print $2}' | sort -n | tail -1`

echo "$sizesXmax" >& /dev/null &
echo "$sizesYmax" >& /dev/null

printf " done - ${inputfileamount} files"
echo -e "\ngenerating atlas..."

resXYs="2048 1024 512 256 128 64 32 16 8 4 2 " # trailing space needed?
atlasID="0"


getminatlassizeX() {
for i in ${resXYs} ; do
	inputvar=`calc -p ${sizesXmax} + 1` # add a pixel
	if [ $inputvar -le $i ] ; then
		newvar=$i
	fi
	echo $newvar
done | sort -unr | tail -1 #  instead of sort ..| tac use   sort .. -r
}


getminatlassizeY() {
for i in ${resXYs} ; do
	inputvar=`calc -p ${sizesYmax} + 1` # same here
	if [ $inputvar -le $i ] ; then
		newvar=$i
	fi
	echo $newvar
done | sort -unr | tail -1  # see above
}


minx=`getminatlassizeX`
miny=`getminatlassizeY`

echo "$minx" > /dev/null &
echo "$miny" > /dev/null

echo -e "\nsmallest atlas will be ${TEAL}${minx}${NC}x${TEAL}${miny}${NC}\n"


resXs=`echo ${resXYs} | grep -o "^.*\ ${minx}\ "`
resYs=`echo ${resXYs} | grep -o "^.*\ ${miny}\ "`


echo -e "global px   atlases\t size b\t\t  ID \t\t   res \t\t 1st Atlas Eff \t global efficiency "



for x in ${resXs} ; do
	for y in ${resYs} ; do
		atlasID=`calc -p ${atlasID}+1`
		make_atlas atlas_${atlasID}_ $x $y atlas_${atlasID}.txt  ${inputfiles}  >&  tmp${atlasID}.tmp
		# add some multitasking here if possible
		images=`find . | grep "atlas_${atlasID}_[0-9]*.png"`
		atlasamount=`find . | grep "atlas_${atlasID}_[0-9]*.png" | wc -l`
		sizepx=`identify ${images} | awk  '{print $3}'  | tr "x" "*" | calc -p | awk '{ sum+=$1} END {print sum}'`
		efficiencysum=`cat tmp${atlasID}.tmp | awk '{print $18}' | sed s/\.$// | awk '{ sum+=$1} END {print sum}'`
		efficiencyratio=`calc -p $efficiencysum /$atlasamount` # note: this is the efficiency of ALL atlas parts, not only the first one, this is GLOBAL EFFICIENCY
		atlasbytesize=`du -sb atlas_${atlasID}_[0-9]*.png  | awk '{print $1}' | awk '{ sum+=$1} END {print sum}'` # unify both awks?

		firstatlasefficiency=`cat tmp${atlasID}.tmp | head -2 | tail -1 | sed s/\.$// | awk '{print $18}'`



		firstatlasefficiency_original=$firstatlasefficiency
		echo $firstatlasefficiency_original > /dev/null # create var now!


		if [[ $firstatlasefficiency > "0.8999999999" ]] ; then
			firstatlasefficiency="${BLUE} ${firstatlasefficiency}${NC}"
		elif [[ $firstatlasefficiency > "0.7999999999" ]] ; then
			firstatlasefficiency="${GREEN} ${firstatlasefficiency}${NC}"
		elif [[ $firstatlasefficiency > "0.49999999999" ]] ; then
			firstatlasefficiency="${YELLOW} ${firstatlasefficiency}${NC}"
		elif [[ $firstatlasefficiency < "0.499999999999" ]] ; then
			firstatlasefficiency="${RED} ${firstatlasefficiency}${NC}"
		fi


		efficiencyratio_original=$efficiencyratio
		echo $efficiencyratio_original > /dev/null # create var now!


		if [[ $efficiencyratio > "0.8999999999" ]] ; then
			efficiencyratio="${BLUE} ${efficiencyratio}${NC}"
		elif [[ $efficiencyratio > "0.7999999999" ]] ; then
			efficiencyratio="${GREEN} ${efficiencyratio}${NC}"
		elif [[ $efficiencyratio > "0.49999999999" ]] ; then
			efficiencyratio="${YELLOW} ${efficiencyratio}${NC}"
		elif [[ $efficiencyratio < "0.499999999999" ]] ; then
			efficiencyratio="${RED} ${efficiencyratio}${NC}"
		fi

		echo -e " $sizepx px,\t$atlasamount\t$atlasbytesize b\t  ID $atlasID, \t${x}x${y}   \t$firstatlasefficiency\t$efficiencyratio"
		firstatlasefficiency=$firstatlasefficiency_original

		efficiencyratio=$efficiencyratio_original
		echo " $sizepx px, $atlasamount atlas  $atlasbytesize b  ID $atlasID, ${x}x${y}  $firstatlasefficiency  $efficiencyratio " >> ./GLOBAL_LOG

	done
done


echo -e "\n\n\n"
#echo "ranking:"
#cat GLOBAL_LOG | sort -n
#echo "first atlas efficiency"
#cat GLOBAL_LOG | sed s/~// | awk '{print $10" "$8}' | sort -nr | head # 1st atlas efficiency
#echo "global efficiency"
#cat GLOBAL_LOG | sed s/~// | awk '{print $11" "$8}' | sort -nr  | head # global  efficiency

}
gen_atlas # funct

echo "best result:"
#cat GLOBAL_LOG | grep "\ 2\ atlas" | awk '{print $1" "$2" "$3" "$4" "$10" "$5" "$6" "$7" "$8   }' | sort -nr | head -n1
#echo "atlas ID:"
bestID=`cat GLOBAL_LOG | grep "\ 2\ atlas" | awk '{print $1" "$2" "$3" "$4" "$10" "$5" "$6" "$7" "$8   }' | sort -nr   | head -n1 | awk '{print $9}' | grep -o "[0-9]*"`

if [ -z $bestID ] ; then
	echo -e "${RED}WARNING!! could not find two atlas images${NC}"
	exit # in future, don't exit here
fi

echo "Atlas ID $bestID"
firststats=`cat GLOBAL_LOG | grep "\ ID\ ${bestID}" | sed s/,$//`
echo ${firststats}
#echo "copying best solution to tmp"
mkdir /tmp/atlasscript/
copyfiles=`find | grep -e "atlas_${bestID}_" -e "atlas_${bestID}\.txt"`
#echo $copyfiles


for i in "$copyfiles" ; do
	cp $i /tmp/atlasscript/
done
rm /tmp/atlasscript/atlas_${bestID}_2.png # hack


dir=`pwd`
#echo "current dir = $dir"
#set -x

#cat atlas_${bestID}.txt  awk '/\*\ atlas_${bestID}_2/,/^$/'

# cat atlas_${bestID}.txt | grep -n "atlas_${bestID}_2" | cut -d":" -f1  # the line we need to search for


# HACK v !, do this properly with awk later!
cat atlas_${bestID}.txt | grep "atlas_${bestID}_2.png" -A999999999999999999   | sed -e '/^\*/d' | awk '{print $1}' > post_used_files  # -A = lines after match,  sed will rm first line in this case



mkdir post_use
cp `cat post_used_files` ./post_use/
cp `cat post_used_files | sed s/png$/offset/` ./post_use/ # don't forget the offset files, argh!
cd ./post_use/



echo -e "${RED}\tentering dir post_use${NC}"
gen_atlas # funct




#echo -e "\n\ninteresting stuff: (req: 1 atlases, first one is best one over all)"

#cat GLOBAL_LOG | grep "\ 1\ atlas" | sort -n | head -n1

#echo "atlas ID:"
bestID=`cat GLOBAL_LOG | grep "\ 1\ atlas" | sort -n | head -n1 | awk '{print $8}' | grep -o "[0-9]*"`

if [ -z $bestID ] ; then
	echo -e "${RED}WARNING!! could not find two atlas images${NC}"
	exit
fi


echo "best result: Atlas ID $bestID"
secondstats=`cat GLOBAL_LOG | grep "\ ID\ ${bestID}," | sed s/,$//`
echo "$secondstats"
#echo "copying best solution to tmp"
mkdir /tmp/atlasscript/post/
copyfiles=`find | grep -e "atlas_${bestID}_" -e "atlas_${bestID}\.txt"`
#echo $copyfiles


for i in "$copyfiles" ; do
	cp $i /tmp/atlasscript/post/
done


#set -x

#cat atlas_${bestID}.txt  awk '/\*\ atlas_${bestID}_2/,/^$/'

# cat atlas_${bestID}.txt | grep -n "atlas_${bestID}_2" | cut -d":" -f1  # the line we need to search for


# HACK v !, do this properly with awk later!
#cat atlas_${bestID}.txt | grep "atlas_${bestID}_2.png" -A999999999999999999   | sed -e '/^\*/d' | awk '{print $1}' > post_used_files  # -A = lines after match,  sed will rm first line in this case








echo  -e "${RED}\tleaving dir post_use${NC}"
cd ../

echo -e "${RED}\tentering dir /tmp/atlasscript/${NC}"
cd /tmp/atlasscript/


atlastmpID=`find | grep "\./atlas.*\.txt" | grep -o "[0-9]*"`

cat ./atlas_${atlastmpID}\.txt | grep "atlas_${atlastmpID}_2" -B99999999  | sed /atlas_${atlastmpID}_2/d  | sed s/atlas_${atlastmpID}/atlas/ > atlas.txt # hack
rm atlas_${atlastmpID}.txt
mv atlas_${atlastmpID}_1.png atlas_1.png
echo -e "${RED}\tentering dir /tmp/atlasscript/post/${NC}"
cd /tmp/atlasscript/post

atlastmpID=`find | grep "\./atlas.*\.txt" | grep -o "[0-9]*"`
#echo "atlastmpID $atlastmpID"
cat atlas_${atlastmpID}.txt | sed -e 's/\*\ atlas.*g\ /*\ atlas_2.png\ /' >> ../atlas.txt

#cat ./atlas_${atlastmpID}\.txt | grep "atlas_${atlastmpID}_2" -B99999999  | sed /atlas_${atlastmpID}_2/d  | sed s/atlas_${atlastmpID}/atlas/ > atlas.txt # hack
mv atlas_${atlastmpID}_1.png ../atlas_2.png
cd ../
rm -rf ./post/
echo -e "moving back to ${RED} $dir ${NC}"
cd $dir


cp ./GLOBAL_LOG /tmp/atlasscript/GLOBAL_LOG

#cat ./GLOBAL_LOG





#echo bar

echo "cleaning up..."
#echo "NOT cleaning up"
git clean -dfqx

cp /tmp/atlasscript/atlas_1.png .
cp /tmp/atlasscript/atlas_2.png .
cat /tmp/atlasscript/atlas.txt  | sed s@\./@@  > atlas.txt # @ instead of / works


echo -e "${RED}done${NC}"




#firststats=`cat GLOBAL_LOG | grep "\ ID\ ${bestID}" | sed s/,$//`
#secondstats=`cat GLOBAL_LOG | grep "\ ID\ ${bestID}," | sed s/,$//`

echo "1st atlas image:"
efficiency_final_sum1=`echo $firststats | awk '{print $10}'`
efficiency_final_sum2=`echo $secondstats  | awk '{print $10}'`
efficiency_final_sum_sum=`calc -p $efficiency_final_sum1 + $efficiency_final_sum2`
efficiency_final_sum_sum_sum=`calc -p $efficiency_final_sum_sum/2`

echo $efficiency_final_sum_sum_sum


echo -e "${TEAL}-------------------------------------------------------------------------------------${NC}"
echo "Composed atlas: part 1"
echo $firststats $efficiency_final_sum_sum_sum | awk '{print $1" "$2" "$5" "$6" "$9" "$10" "$11}'
#echo  $firststats $efficiency_final_sum_sum_sum

echo "Composed atlas: part 2"
echo $secondstats $efficiency_final_sum_sum_sum | awk '{print $1" "$2" "$5" "$6" "$9" "$10" "$12}'
echo -e "${TEAL}----------------------------------------${NC}"


echo "Best result of classic atlas generation:"
bestnormalatlas=`cat /tmp/atlasscript/GLOBAL_LOG | grep -e ",\ 2\ atlas" -e ",\ 1\ atlas" -e ",\ 3\ atlas" -e ",\ 4\ atlas"| awk '{print $3" "$4", "$7" "$8" "$11}' | sort -n -k5 | tail -1`
bestnormalatlas2=`echo "$bestnormalatlas" | awk '{print $3" "$4}'`
bestnormalatlas_final=`cat /tmp/atlasscript/GLOBAL_LOG | grep "${bestnormalatlas2}"`
cat /tmp/atlasscript/GLOBAL_LOG | grep "${bestnormalatlas2}"
bestnormalatlas_global_eff=`echo "${bestnormalatlas}" | awk '{print $5}'`
bestnormalatas_res=`cat /tmp/atlasscript/GLOBAL_LOG | grep "${bestnormalatlas2}" | awk '{print $9}' | tr "x" " "`

echo -e "${TEAL}----------------------------------------${NC}"


if [[ "${bestnormalatlas_global_eff}" > "${efficiency_final_sum_sum_sum}" ]] ; then # composed atlas is best

	echo "Classic atlas is best"
	rm atlas_1.png atlas_2.png atlas.txt
	make_atlas atlas ${bestnormalatas_res} atlas.txt ${inputfiles2}
#echo "	make_atlas atlas ${bestnormalatas_res} atlas ${inputfiles2}"

else
	echo "Composed atlas is best"
fi

echo -e "${YELLOW}---------------------------------------------${NC}"
echo -e "${YELLOW}---------------------------------------------${NC}"

echo "Checking if we can do further optimizations..."

rm -r /tmp/atlasscript

further_optim_res=`head -n1 atlas.txt | awk '{print $4" "$5}'`

further_optim_res_regex=`echo "$further_optim_res" | sed -e 's/\ /\\ /'`


if  [ "`grep -e "${further_optim_res_regex}" atlas.txt | head -n2 | wc -l `" == "2" ] ; then
# yes, we can probably merge 2 64x32 into one 128 x 32 or 64 x 64 atlas
	echo "Yes"
	further_optim_images=`cat atlas.txt | awk /\*.*1\.png/,/\*.*3\.png/ | grep -v "^\*" | awk '{print $1}'` # images of the first 2 atlases


# X
	further_optim_res_x=`echo ${further_optim_res} | awk '{print $1}'`
	further_optim_res_fixedx=`calc -p 2\*${further_optim_res_x}`

	if [[ "${further_optim_res_fixedx}" == "4096" ]] ; then # we cannot have sizes above 2048, so limit here
		further_optim_res_fixedx="2048"
	fi

# Y
	further_optim_res_y=`echo ${further_optim_res} | awk '{print $2}'`
	further_optim_res_fixedy=`calc -p 2\*${further_optim_res_y}`

	if [[ "${further_optim_res_fixedy}" == "4096" ]] ; then # same here
		further_optim_res_fixedy="2048"
	fi


	further_optim_res_final1=`echo "${further_optim_res_x} ${further_optim_res_fixedy}"`

	further_optim_res_final2=`echo "${further_optim_res_fixedx} ${further_optim_res_y}"`

#echo $further_optim_res_final1
#echo $further_optim_res_final2

	printf "\nCreating new workdir..."

	mkdir foo #copy the images
	cp ${further_optim_images} ./foo/
	bla_offset=`echo ${further_optim_images} | sed s/\.png/\.offset/g`
	cp ${bla_offset} ./foo/
	cd foo

	printf " done\n\n"

	echo -e "\nCreating atlas ${further_optim_res_final1}"
	make_atlas atlas1_ ${further_optim_res_final1} atlas1.txt ${further_optim_images}
	further_optim_res_final1_2=`echo "$further_optim_res" | awk '{print $2" "$1}'`

	echo -e "\nCreating atlas ${further_optim_res_final1_2}"
	make_atlas atlas2_ ${further_optim_res_final1_2} atlas2.txt ${further_optim_images}


	echo -e "\nCreating atlas ${further_optim_res_final2}"
	make_atlas atlas3_ ${further_optim_res_final2} atlas3.txt ${further_optim_images}
	further_optim_res_final2_2=`echo "$further_optim_res" | awk '{print $2" "$1}'`

	echo -e "\nCreating atlas ${further_optim_res_final2_2}"
	make_atlas atlas4_ ${further_optim_res_final2_2} atlas4.txt ${further_optim_images}




	foo_atlas1_numb=`find | grep "atlas1.*" | wc -l`
	foo_atlas2_numb=`find | grep "atlas2.*" | wc -l`

	if [[ "${foo_atlas1_numb}" < "${foo_atlas2_numb}" ]] ; then # atlas 1 is better
		further_optim_res_good=${further_optim_res}
	else
		further_optim_res_good=${further_optim_res_second}
	fi
	echo "${further_optim_res_good} is good"

	for i in {1..4} ; do
		bla_foo_numb=`find | grep "atlas${i}_.*\.png" | wc -l`
		if [[ "${bla_foo_numb}" == "1" ]] ; then
			cd ../  # edit atlas.txt
			cat atlas.txt | awk /\*\ atlas3/,/^$/ > atlas_bkp.txt
			rm atlas1.png atlas2.png
			cd ./foo
			cp atlas${i}_1.png ../atlas1.png
			cd ../
			mv atlas3.png atlas2.png >& /dev/null
			mv atlas4.png atlas3.png >& /dev/null
			mv atlas5.png atlas4.png >& /dev/null
			mv atlas6.png atlas5.png >& /dev/null
			mv atlas7.png atlas6.png >& /dev/null
			cat atlas_bkp.txt | sed -e 's/atlas3/atlas2/' | sed  -e 's/atlas4/atlas3/' > text
			cat ./foo/atlas1.txt | sed -e 's/atlas1_1/atlas1/' > ./final.txt
			cat text >> final.txt
			cat final.txt |  sed -e 's/\.\///' > atlas.txt
			rm text atlas_bkp.txt final.txt
		fi
	done
else
	echo "No."
fi
rm -rf ./foo
