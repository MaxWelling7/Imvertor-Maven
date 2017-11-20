<?xml version="1.0" encoding="UTF-8"?>
<!-- 
 * Copyright (C) 2016 Dienst voor het kadaster en de openbare registers
 * 
 * This file is part of Imvertor.
 *
 * Imvertor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Imvertor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Imvertor.  If not, see <http://www.gnu.org/licenses/>.
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 

    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    exclude-result-prefixes="#all" 
    version="2.0">

    <!-- 
        Pick up any stubs and translate these to the external or internal packages they are defined in.
    -->
    
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-conceptual-map.xsl"/>
        
    <xsl:variable name="outside-mapped-classes" as="element(imvert:class)*">
        <xsl:for-each select="//imvert:package[imvert:id = 'OUTSIDE']/imvert:class"> <!-- all stubs -->
            <xsl:variable name="constructs" select="$conceptual-schema-mapping//construct[name = current()/imvert:name]" as="element(construct)*"/>
            <xsl:variable name="construct" as="element(construct)?">
                <xsl:choose>
                    <xsl:when test="$constructs[2]">
                        <xsl:sequence select="$constructs[managed-ids/id = current()/imvert:id][1]"/>
                    </xsl:when>
                    <xsl:when test="$constructs[1]">
                        <xsl:sequence select="$constructs"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="imf:msg('WARN','Reference to [1] in outside model could not be resolved when using mapping [2]',(imvert:name,$conceptual-schema-mapping-name))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- 
                We have drilled down to single construct (or none if error) 
                Get the URL of the conceptual schema this is part of.
            -->
            <xsl:variable name="cs" select="($construct/ancestor::conceptual-schema/url)[1]"/>
            <xsl:variable name="cn" select="($construct/ancestor::conceptual-schema/name)[1]"/>
            <xsl:variable name="sn" select="($construct/ancestor::conceptual-schema/short-name)[1]"/>
            <xsl:variable name="ve" select="($construct/ancestor::map/@version)[1]"/>
            <xsl:variable name="ph" select="($construct/ancestor::map/@phase)[1]"/>
            
            <imvert:class origin="system" cs="{$cs}" cn="{$cn}" sn="{$sn}" ve="{$ve}" ph="{$ph}">
                <imvert:name original="{imvert:name}">
                    <xsl:value-of select="imvert:name"/>
                </imvert:name>
                <imvert:id>
                    <xsl:value-of select="imvert:id"/>
                </imvert:id>
                <imvert:catalog>
                    <xsl:sequence select="imf:create-catalog-url($construct)"/>     
                </imvert:catalog>
                <imvert:stereotype id="CFG-ST-INTERFACE">
                    <xsl:value-of select="imf:get-config-stereotypes('stereotype-name-interface')"/>
                </imvert:stereotype>
            </imvert:class>
        </xsl:for-each>
    </xsl:variable>    
    
    <xsl:template match="/imvert:packages">
        <xsl:copy>
            <xsl:sequence select="imf:compile-imvert-header(.)"/>
            <xsl:apply-templates select="imvert:package"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="imvert:package[imvert:id = 'OUTSIDE']">
        <!--
           we now have a set of maps; must group them together and build external packages from these.
        -->
        <xsl:for-each-group select="$outside-mapped-classes" group-by="@cs">
            <imvert:package origin="system">
                <imvert:id>
                    <xsl:value-of select="concat('GENERATED-PACKAGE-ID-',position())"/>
                </imvert:id>
                <imvert:version>
                    <xsl:value-of select="current-group()[1]/@ve"/>
                </imvert:version>
                <imvert:phase original="final">
                    <xsl:value-of select="current-group()[1]/@ph"/>
                </imvert:phase>
                <imvert:name original="{current-group()[1]/@cn}">
                    <xsl:value-of select="current-group()[1]/@cn"/>
                </imvert:name>
                <imvert:short-name>
                    <xsl:value-of select="current-group()[1]/@sn"/>
                </imvert:short-name>
                <imvert:alias>
                    <xsl:value-of select="current-grouping-key()"/>
                </imvert:alias>
                <imvert:namespace>
                    <xsl:value-of select="current-grouping-key()"/>
                </imvert:namespace>
                <imvert:stereotype id="CFG-ST-EXTERNAL">
                    <xsl:value-of select="imf:get-config-stereotypes('stereotype-name-external-package')"/>
                </imvert:stereotype>
                <!-- and list all classes -->
                <xsl:sequence select="current-group()"/>
            </imvert:package>
        </xsl:for-each-group>
    </xsl:template>
        
    <xsl:template match="imvert:type-package[. = 'OUTSIDE']">
        <!-- replace this package name by the mapped name -->    
        <xsl:variable name="type-id" select="../imvert:type-id"/>
        <xsl:variable name="outside-class" select="$outside-mapped-classes[imvert:id = $type-id]"/>
        <xsl:variable name="outside-package-name" select="$outside-class/@cn"/>
        <imvert:type-package original="$outside-package-name" origin="OUTSIDE">
            <xsl:value-of select="$outside-package-name"/>
        </imvert:type-package>
    </xsl:template>
  
    <xsl:template match="node()" mode="#all">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
