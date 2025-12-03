<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- Group original testsuite elements by "Child Folder X" (middle segment of @name)
       Example @name: "Parent Folder / Child Folder 1 / Sample Request 1a" -->
  <xsl:key name="by-child"
           match="testsuite"
           use="substring-before(substring-after(@name,' / '),' / ')" />

  <xsl:template match="/testsuites">
    <testsuites>
      <!-- Keep top-level attributes like name, time, etc. -->
      <xsl:copy-of select="@*"/>

      <!-- Parent folder name from the first testsuite -->
      <xsl:variable name="parentName"
                    select="substring-before(testsuite[1]/@name, ' / ')" />

      <!-- For each DISTINCT Child Folder -->
      <xsl:for-each select="testsuite[
                              generate-id()
                              =
                              generate-id(
                                key('by-child',
                                    substring-before(
                                      substring-after(@name,' / '),' / '
                                    )
                                )[1]
                              )
                            ]">
        <!-- Child folder name, e.g. "Child Folder 1" -->
        <xsl:variable name="childName"
                      select="substring-before(substring-after(@name,' / '),' / ')" />

        <!-- All original testsuites that belong to this Child Folder -->
        <xsl:variable name="childSuites"
                      select="/testsuites/testsuite
                                [substring-before(substring-after(@name,' / '),' / ')
                                 = $childName]" />

        <!-- All underlying assertion-level testcases in this Child Folder -->
        <xsl:variable name="childCases" select="$childSuites/testcase"/>
        <xsl:variable name="childFailed" select="$childCases[failure]"/>
        <xsl:variable name="childErrored" select="$childCases[error]"/>

        <!-- Use id/timestamp from the first testsuite in this Child Folder (if present) -->
        <xsl:variable name="childId" select="$childSuites[1]/@id"/>
        <xsl:variable name="childTs" select="$childSuites[1]/@timestamp"/>

        <!-- New testsuite for this Child Folder -->
        <testsuite
          name="{concat($parentName, ' / ', $childName)}"
          id="{$childId}"
          timestamp="{$childTs}"
          tests="{count($childCases)}"
          failures="{count($childFailed)}"
          errors="{count($childErrored)}"
          time="{sum($childCases/@time)}">

          <!-- One testcase per API request (original testsuite) -->
          <xsl:for-each select="$childSuites">
            <!-- Request name, e.g. "Sample Request 1a" -->
            <xsl:variable name="requestName"
                          select="substring-after(substring-after(@name,' / '),' / ')" />
            <!-- All assertion-level testcases for this request -->
            <xsl:variable name="reqCases" select="testcase"/>
            <xsl:variable name="reqFailed" select="$reqCases[failure]"/>
            <xsl:variable name="reqErrored" select="$reqCases[error]"/>

            <testcase
              name="{$requestName}"
              time="{sum($reqCases/@time)}">

              <!-- If any underlying assertion failed/errored, this request fails -->
              <xsl:if test="count($reqFailed) + count($reqErrored) &gt; 0">
                <!-- Preserve all original <failure> / <error> elements (full context) -->
                <xsl:copy-of select="$reqCases/failure | $reqCases/error"/>
              </xsl:if>
            </testcase>
          </xsl:for-each>
        </testsuite>
      </xsl:for-each>
    </testsuites>
  </xsl:template>

</xsl:stylesheet>

