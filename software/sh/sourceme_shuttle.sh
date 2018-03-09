export DOCX2JATSFOLDER=/usr/local/docx2jats

export SOFTWAREFOLDER=$DOCX2JATSFOLDER/software
export SHFOLDER=$SOFTWAREFOLDER/sh
export XPLFOLDER=$SOFTWAREFOLDER/xpl

export SAXONFOLDER=/usr/local/saxon
export CALABASHFOLDER=/usr/local/calabash
export SAXONJAR=$SAXONFOLDER/saxon9pe.jar
export CALABASH_JAR=$CALABASHFOLDER/xmlcalabash.jar

export JAVA_HOME=/usr/local/jdk

export JAVACMD=$JAVA_HOME/bin/java

if [ -z "$PREFIX_TO_RNG_SCHEMA" ]
then
  PREFIX_TO_RNG_SCHEMA=./
  export PREFIX_TO_RNG_SCHEMA
fi

if [ -z "$PREFIX_TO_SCH_SCHEMA" ]
then
  PREFIX_TO_SCH_SCHEMA=./
  export PREFIX_TO_SCH_SCHEMA
fi