<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" indent="yes" />
	
	<xsl:param name="page-limit" />
	<xsl:param name="avg-limit" />
	<xsl:param name="skip" />
	<xsl:param name="rules-file" />
	<xsl:param name="dictionary" select="document($rules-file,/)"/>

	<xsl:template match="/">
		<testsuites>
			<xsl:apply-templates />
		</testsuites>
	</xsl:template>

	<xsl:template name="results" match="results">
		<xsl:variable name="url" select="substring-before(concat(curl, '?'), '?')" />
		<xsl:variable name="tests" select="count(g/*)" />
		<xsl:variable name="failures" select="count(g/*[score&lt;$page-limit])" />
		<xsl:variable name="skipped" select="count(g/*[contains($skip,name(.))])" />

		<xsl:variable name="sum" select="sum(g/*/score)"/>
		<xsl:variable name="avg-score" select="$sum div $tests"/>
		<xsl:variable name="avg-score-decimals" select="format-number($avg-score, '0.00')" />		

		<!--Taking care of the case when the overall fails -->
        <xsl:variable name="avg-fail">
		   <xsl:choose>
		        <xsl:when test="$avg-score-decimals&lt;$avg-limit">1</xsl:when>
		        <xsl:otherwise>0</xsl:otherwise>
		    </xsl:choose>
		</xsl:variable>	

		<!-- Replacing all . with _ for better junit results -->
		<xsl:variable name="junit-url">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$url"/>
                <xsl:with-param name="replace">.</xsl:with-param>
                <xsl:with-param name="by" select="'_'"/>
            </xsl:call-template>
        </xsl:variable>
	

		<!-- Adding one extra test for the overall score -->
		<testsuite name="sitespeed&#46;io.{$junit-url}" tests="{$tests+1}"
			failures="{$failures+$avg-fail}" skipped="{$skipped}">
			<testcase name="Overall average score" status="{$avg-score-decimals}">
			    <xsl:if test="$avg-score-decimals&lt;$avg-limit">
			        <failure message="The average overall score is below your limit of {$avg-limit}"/>
			    </xsl:if>
			</testcase>	
			<xsl:apply-templates />
		</testsuite>
	</xsl:template>

	<xsl:template match="g/*">
		<xsl:variable name="testkey" select="name(.)" />
		<xsl:variable name="testname" select="$dictionary/results/dictionary/rules/*[contains($testkey,name(.))]/name" />
		<xsl:variable name="score" select="score" />
		<testcase name="{$testkey}: {$testname}" status="{$score}" time="0.1">
			<!-- Checked if skipped -->
			<xsl:if test="contains($skip,$testkey)">
				<skipped></skipped>
			</xsl:if>
			<xsl:if test="$score&lt;$page-limit">
				<xsl:variable name="message" select="message" />

				<failure message="{$message}">
					<xsl:for-each select="components/item">
						<xsl:text>&#xa;</xsl:text>
						<xsl:value-of select="." />
					</xsl:for-each>
				</failure>
			</xsl:if>
		</testcase>
	</xsl:template>

	<xsl:template match="w|o|u|i|r|lt|url|curl|stats|comps|w_c|r_c|stats_c">
	<!-- skip these -->
	</xsl:template>

<!-- Classic replace template -->
<xsl:template name="string-replace-all"> 
        <xsl:param name="text"/> 
        <xsl:param name="replace"/> 
        <xsl:param name="by"/> 
        <xsl:choose> 
            <xsl:when test="contains($text,$replace)"> 
                <xsl:value-of select="substring-before($text,$replace)"/> 
                <xsl:value-of select="$by"/> 
                <xsl:call-template name="string-replace-all"> 
                    <xsl:with-param name="text" select="substring-after($text,$replace)"/> 
                    <xsl:with-param name="replace" select="$replace"/> 
                    <xsl:with-param name="by" select="$by"/> 
                </xsl:call-template> 
            </xsl:when> 
    <xsl:otherwise> 
      <xsl:value-of select="$text"/> 
    </xsl:otherwise> 
  </xsl:choose> 
</xsl:template> 

</xsl:stylesheet>



