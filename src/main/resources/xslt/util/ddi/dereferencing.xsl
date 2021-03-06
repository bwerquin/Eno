<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" 
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:d="ddi:datacollection:3_2"
    xmlns:r="ddi:reusable:3_2" xmlns:l="ddi:logicalproduct:3_2" xmlns:g="ddi:group:3_2"
    xmlns:s="ddi:studyunit:3_2" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>This stylesheet is used to dereference DDI.</xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>
            <xd:p>The output folder in which the dereferenced files (one for each main sequence) are generated.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="output-folder"/>

    <!-- The output file generated will be xml type -->
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:strip-space elements="*"/>

    <xd:doc>
        <xd:desc>
            <xd:p>Successively, some group of elements is used to dereference some other group of elements.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="calculated-variables-sequences" as="node()">
        <Variables>
            <xsl:for-each select="//d:GenerationInstruction/d:ControlConstructReference">
                <Variable>
                    <xsl:value-of select="r:ID"/>
                </Variable>
            </xsl:for-each>
        </Variables>
    </xsl:variable>    

    <xd:doc>
        <xd:desc>
            <xd:p>Root template :</xd:p>
            <xd:p>Successively, some group of elements is used to dereference some other group of elements.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <!-- The references used to dereference at the beginning -->
        <xsl:variable name="references-for-codelists">
            <xsl:element name="g:ResourcePackage">
                <xsl:copy-of select="//l:CodeListScheme"/>
                <xsl:copy-of select="//l:CategoryScheme"/>
                <xsl:copy-of select="//d:InterviewerInstructionScheme"/>
            </xsl:element>
        </xsl:variable>
        <!-- The l:CodeListScheme are dereferenced -->
        <xsl:variable name="dereferenced-codelists">
            <xsl:element name="g:ResourcePackage">
                <xsl:apply-templates select="//l:CodeListScheme">
                    <xsl:with-param name="references" select="$references-for-codelists" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:variable>

        <!-- The dereferenced l:CodeListScheme, the d:InterviewerInstructionScheme, the r:ManagedRepresentationScheme and the d:QuestionScheme are used as new references -->
        <xsl:variable name="references-for-questions">
            <xsl:copy-of select="//d:QuestionScheme"/>
            <xsl:copy-of select="//d:InterviewerInstructionScheme"/>
            <xsl:copy-of select="//r:ManagedRepresentationScheme"/>
            <xsl:copy-of select="//d:ProcessingInstructionScheme"/>
            <xsl:copy-of select="$dereferenced-codelists//l:CodeListScheme"/>
        </xsl:variable>

        <!-- The d:QuestionScheme are dereferenced -->
        <xsl:variable name="dereferenced-questions">
            <xsl:element name="g:ResourcePackage">
                <xsl:apply-templates select="//d:QuestionScheme">
                    <xsl:with-param name="references" select="$references-for-questions" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:variable>

        <!-- The dereferenced d:QuestionScheme, the d:InterviewerInstructionScheme, and the ControlConstructScheme are used as new references -->
        <xsl:variable name="references-for-template-sequence">
            <xsl:copy-of select="//d:ControlConstructScheme"/>
            <xsl:copy-of select="//d:InterviewerInstructionScheme"/>
            <xsl:copy-of select="//d:ProcessingInstructionScheme"/>
            <xsl:copy-of select="$dereferenced-questions//d:QuestionScheme"/>
        </xsl:variable>

        <!-- The main sequences of the DDI are dereferenced -->
        <xsl:variable name="dereferenced-template-sequence">
            <xsl:element name="g:ResourcePackage">
                <xsl:apply-templates
                    select="//d:ControlConstructScheme/d:Sequence[d:TypeOfSequence/text() = 'template']">
                    <xsl:with-param name="references" select="$references-for-template-sequence" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:variable>

        <!-- The l:VariableScheme are used as new references -->
        <xsl:variable name="references-variables">
            <xsl:copy-of select="//l:VariableScheme"/>
        </xsl:variable>

        <!-- The root of all identifiers in the survey -->
        <xsl:variable name="root">
            <xsl:value-of select="replace(//s:StudyUnit/r:ID/text(), '-SU', '')"/>
        </xsl:variable>

        <!-- Then each d:Instrument is dereferenced with the previous dereferenced tree used as references -->
        <xsl:for-each select="//d:Instrument">
            <xsl:result-document
                href="{lower-case(concat('file:///',replace($output-folder, '\\' , '/'),'/',replace(r:ID/text(), concat($root/text(),'-In-'), ''),'.tmp'))}">
                <DDIInstance>
                    <s:StudyUnit>
                        <xsl:apply-templates select=".">
                            <xsl:with-param name="references" select="$dereferenced-template-sequence" tunnel="yes"/>
                        </xsl:apply-templates>
                    </s:StudyUnit>
                    <!-- And the VariableScheme is dereferenced with itself as references -->
                    <!-- Only copying the variables that don't correspond to a question -->
                    <xsl:element name="g:ResourcePackage">
                        <xsl:apply-templates select="//l:VariableScheme">
                            <xsl:with-param name="references" select="$references-variables" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:element>
                </DDIInstance>
            </xsl:result-document>
        </xsl:for-each>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Default template for every element and every attribute, simply copying to the
                output result.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Not retrieving the variables that correspond to a question or a calculated variable.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="l:Variable[r:QuestionReference or r:SourceParameterReference or descendant::r:ProcessingInstructionReference]" priority="1"/>

    <xd:doc>
        <xd:desc>
            <xd:p>Only retrieving the variables which are not corresponding to a question.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="l:Variable[not(r:QuestionReference or r:SourceParameterReference or descendant::r:ProcessingInstructionReference)]"
        priority="1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Template to insert GenerationInstruction, which reference the element they have to be included in.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node()[r:ID=$calculated-variables-sequences/Variable and not(ends-with(name(), 'Reference'))]">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:apply-templates select="//d:GenerationInstruction[d:ControlConstructReference/r:ID=current()/r:ID]"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="d:GenerationInstruction/d:ControlConstructReference"/>
    

    <xd:doc>
        <xd:desc>
            <xd:p>Default template for every element that corresponds to a reference.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node()[ends-with(name(), 'Reference') and not(parent::r:Binding)]/r:ID">
        <xsl:param name="references" tunnel="yes"/>
        <xsl:variable name="ID" select="."/>
        <!-- Copying the element -->
        <!-- Making sure we're not copying an element that isn't itself inside another reference (and that would actually not the base element but an already indexed reference) -->
        <xsl:apply-templates
            select="$references//*[r:ID = $ID and not(ancestor-or-self::node()[ends-with(name(), 'Reference') or starts-with(name(), 'd:Source')])]"
        />
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Instruction are not allowed in Category for DDI 3.2. This template allows to insert tooltips into arrays' labels</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="xhtml:a">
        <xsl:variable name="ref" select="replace(@href,'#','')"/>
        <xsl:variable name="language" select="ancestor::*[@xml:lang][1]/@xml:lang"/>
        
        <xsl:choose>
            <xsl:when test="//*[@id=$ref 
                                and ancestor-or-self::*[@xml:lang][1]/@xml:lang=$language 
                                and ancestor::d:Instruction/d:InstructionName/r:String[@xml:lang=$language]='tooltip']">
                <xsl:element name="xhtml:span">
                    <xsl:attribute name="title">
                        <xsl:value-of select="normalize-space(//*[@id=$ref 
                                                                    and ancestor-or-self::*[@xml:lang][1]/@xml:lang=$language 
                                                                    and ancestor::d:Instruction/d:InstructionName/r:String[@xml:lang=$language]='tooltip'])"/>
                    </xsl:attribute>
                    <xsl:text>&#160;</xsl:text>
                    <xsl:element name="img">
                        <xsl:attribute name="src" select="'/img/Help-browser.svg.png'"/>
                    </xsl:element>
                    <xsl:text>&#160;</xsl:text>
                </xsl:element>            
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
