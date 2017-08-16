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
    xmlns:UML="omg.org/UML1.3"
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    xmlns:ekf="http://EliotKimber/functions"

    exclude-result-prefixes="#all"
    version="2.0">

    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-derivation.xsl"/>
    
    <xsl:variable name="stylesheet-code">SHACL</xsl:variable>
    <xsl:variable name="debugging" select="imf:debug-mode($stylesheet-code)"/>
    
    <xsl:output method="text"/>
    
    <xsl:template match="/">
        <xsl:value-of select="imf:ttl(('# Generated by ', imf:get-config-string('run','version')))"/>
        <xsl:value-of select="imf:ttl(('# Generated at ', imf:get-config-string('run','start')))"/>
        <xsl:value-of select="imf:ttl(())"/>
        
        <!-- 
            read the configured info 
        -->
        <xsl:apply-templates select="$configuration-shaclrules-file//vocabulary" mode="preamble"/>
      
        <xsl:value-of select="imf:ttl(())"/>
        <!-- 
            process the imvertor info 
        -->
        <xsl:apply-templates select="$document-packages" mode="mode-object"/>
        
    </xsl:template>
   
    <xsl:template match="vocabulary" mode="preamble">
        <xsl:value-of select="imf:ttl(('@prefix ',prefix,': &lt;', URI ,'&gt;.'))"/>
    </xsl:template>
    
    <xsl:template match="imvert:package" mode="mode-object">
        <xsl:apply-templates select="imvert:class" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="imvert:class[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-objecttype')]" mode="mode-object">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-construct($this)"/>
        <xsl:value-of select="imf:ttl((imf:ttl-get-full-name($this),' rdf:type kkg:Objecttype;'))"/>
        <xsl:value-of select="imf:ttl((' kkg:naam ',imf:ttl-value($this/imvert:name,'2q'),';'))"/>
        <xsl:value-of select="for $super in imf:get-superclass($this) return imf:ttl((' kkg:verwijstNaarGenerieke ',imf:ttl-get-full-name($super),';'))"/>
        <xsl:sequence select="imf:ttl-get-all-tvs($this)"/>
        
        <!-- loop door alle attributen en associaties heen, en plaats een property (predicate object)-->
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-object"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attributegroup')]" mode="mode-object"/>
        <xsl:apply-templates select="$this/imvert:associations/imvert:association[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-relation-role')]" mode="mode-object"/>
       
        <xsl:value-of select="imf:ttl('.')"/>
        
        <!-- loop door alle attributen en associaties heen, en maak daarvoor een subject -->
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-subject"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attributegroup')]" mode="mode-subject"/>
        <xsl:apply-templates select="$this/imvert:associations/imvert:association[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-relation-role')]" mode="mode-subject"/>

        <!-- maak datatypen voor de primitieve datatypen -->
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-datatype"/>
        
    </xsl:template>
    
    <xsl:template match="imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-object">
        <xsl:variable name="this" select="."/>
        <xsl:value-of select="imf:ttl((' kkg:bezitAttribuutsoort ',imf:ttl-get-full-name($this), ';'))"/>
    </xsl:template>
    
    <xsl:template match="imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-construct($this)"/>
        <xsl:value-of select="imf:ttl((imf:ttl-get-full-name($this),' rdf:type kkg:Attribuutsoort;'))"/>
        <xsl:value-of select="imf:ttl((' kkg:naam ',imf:ttl-value($this/imvert:name,'2q'),';'))"/>
        
        <xsl:variable name="defining-class" select="imf:ttl-get-defining-class($this)"/>
        <xsl:choose>
            <xsl:when test="exists($defining-class)">
                <xsl:value-of select="imf:ttl((' kkg:heeftDatatype ',imf:ttl-get-full-name($defining-class),';'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="datatype-name" select="imf:ttl-get-full-name($this)"/>
                <xsl:value-of select="imf:ttl((' kkg:heeftDatatype data:',$datatype-name,';'))"/>
            </xsl:otherwise>
        </xsl:choose>
       
        <xsl:value-of select="imf:ttl((' kkg:minKardinaliteit ',imf:ttl-value($this/imvert:min-occurs,'2q'),';'))"/>
        <xsl:value-of select="imf:ttl((' kkg:maxKardinaliteit ',imf:ttl-value($this/imvert:max-occurs,'2q'),';'))"/>
        
        <xsl:sequence select="imf:ttl-get-all-tvs($this)"/>
        
        <xsl:value-of select="imf:ttl('.')"/>
        
    </xsl:template>
    
    <xsl:template match="imvert:attribute[imvert:stereotype = imf:get-config-stereotypes('stereotype-name-attribute')]" mode="mode-datatype">
        <xsl:variable name="this" select="."/>
        <xsl:choose>
            <xsl:when test="empty(imvert:type-id)">
            
                <xsl:variable name="datatype-name" select="imf:ttl-get-full-name($this)"/>
                <xsl:value-of select="imf:ttl(($datatype-name,' rdf:type kkg:PrimitiefDatatype',';'))"/>
                <xsl:value-of select="imf:ttl(' # more?')"/>
                <xsl:value-of select="imf:ttl('.')"/>
                
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
        
    <xsl:template match="node()" mode="#all">
        <!-- skip -->        
    </xsl:template>
    
    <xsl:function name="imf:ttl" as="xs:string">
        <xsl:param name="parts" as="item()*"/>
        <xsl:value-of select="string-join(($parts,'&#10;'),'')"/>
    </xsl:function>
    
    <xsl:function name="imf:ttl-construct" as="xs:string">
        <xsl:param name="this" as="item()*"/>
        <xsl:value-of select="imf:ttl(('# Construct: ',imf:get-display-name($this), ' (', string-join($this/imvert:stereotype,', '),')'))"/>
    </xsl:function>
    
    <xsl:variable name="str3quot">'''</xsl:variable>
    <xsl:variable name="str2quot">"</xsl:variable>
    <xsl:variable name="str1quot">'</xsl:variable>
    
    <!-- return (name, type) sequence -->
    <xsl:function name="imf:ttl-map" as="element(map)?">
        <xsl:param name="id"/>
        <xsl:sequence select="$configuration-shaclrules-file//node-mapping/map[@id=$id]"/>
    </xsl:function>
    
    <xsl:function name="imf:ttl-value">
        <xsl:param name="string"/>
        <xsl:param name="type"/>
        <xsl:choose>
            <xsl:when test="$type = '3q'">
                <xsl:value-of select="concat($str3quot,$string,$str3quot)"/>
            </xsl:when>
            <xsl:when test="$type = '2q'">
                <xsl:value-of select="concat($str2quot,$string,$str2quot)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($str1quot,$string,$str1quot)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
        Haal alle tagged values op in TTL statement formaat.
        Dit zijn alle relevante tv's, dus ook die waarvan de waarde is afgeleid.
    -->
    <xsl:function name="imf:ttl-get-all-tvs">
        <xsl:param name="this"/>
        <!-- loop door alle tagged values heen -->
        <xsl:for-each select="imf:get-config-applicable-tagged-value-ids($this)">
            <xsl:variable name="tv" select="imf:get-most-relevant-compiled-taggedvalue-element($this,concat('##',.))"/>
            <xsl:variable name="map" select="imf:ttl-map($tv/@id)"/>
            <xsl:if test="exists($tv) and exists($map)">
                <xsl:value-of select="imf:ttl((' ', $map, ' ', imf:ttl-value($tv/@value,$map/@type),';'))"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    <!-- 
        return for passed attribute or assoc the class when this is defined in terms of classes 
    -->
    <xsl:function name="imf:ttl-get-defining-class" as="element()?">
        <xsl:param name="this"/>
        <xsl:variable name="type-id" select="$this/imvert:type-id"/>
        <xsl:if test="exists($type-id)">
            <xsl:sequence select="$document-classes[imvert:id = $type-id]"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:ttl-get-full-name">
        <xsl:param name="class"/>
        <!--
        <xsl:variable name="dn" select="subsequence(tokenize(imf:get-display-name($class),'\s\('),1,1)"/>
        <xsl:value-of select="concat('data:', string-join(tokenize($dn,'[^A-Za-z0-9]+'),'_'))"/>
        -->
        <xsl:value-of select="concat('data:', $class/@formal-name)"/>
    </xsl:function>
        
</xsl:stylesheet>
