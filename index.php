<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<title>Zedom8or</title>
<style type="text/css">
<!--
body {
	font: 100%/1.4 Verdana, Arial, Helvetica, sans-serif;
	background-color: #000;
	margin: 0;
	padding: 0;
	color: #000;
}
li {
	border-right: 3px #DDD solid;
}
ul, ol, dl {
	padding: 0;
	margin: 0;
}
h1, h2, h3, h4, h5, h6, p {
	margin-top: 0;
	padding-right: 15px;
	padding-left: 15px;
}
a img {
	border: none;
}
a:link {
	color: #DDF;
	text-decoration: underline;
}
a:visited {
	color: #DDF;
	text-decoration: underline;
}
a:hover, a:active, a:focus { /* this group of selectors will give a keyboard navigator the same hover experience as the person using a mouse. */
	color: #DDF;
	text-decoration: none;
}
/* ~~ this container surrounds all other divs giving them their percentage-based width ~~ */
.container {
	width: 100%;
	max-width: 1280px;/* a max-width may be desirable to keep this layout from getting too wide on a large monitor. This keeps line length more readable. IE6 does not respect this declaration. */
	min-width: 780px;/* a min-width may be desirable to keep this layout from getting too narrow. This keeps line length more readable in the side columns. IE6 does not respect this declaration. */
	background-color: #000;
	color: #FFF;/*margin: 0 auto;*/ /* the auto value on the sides, coupled with the width, centers the layout. It is not needed if you set the .container's width to 100%. */
}
/* ~~ the header is not given a width. It will extend the full width of your layout. It contains an image placeholder that should be replaced with your own linked logo ~~ */
.header {
	background-color: #000;
	display: block;
	width: 100%;
}
.sidebar1 {
	float: left;
	width: 20%;
	background-color: #000;
	padding-bottom: 0px;
}
.content {
	padding: 0px;
	width: 80%;
	float: left;
}
.content ul, .content ol {
	padding: 0 15px 15px 40px;
}
ul.nav {
	list-style: none; /* this removes the list marker */
	border-top: 1px solid #666; /* this creates the top border for the links - all others are placed using a bottom border on the LI */
	margin-bottom: 0px; /* this creates the space between the navigation on the content below */
}
ul.nav li {
	border-bottom: 1px solid #666; /* this creates the button separation */
}
ul.nav a, ul.nav a:visited { /* grouping these selectors makes sure that your links retain their button look even after being visited */
	padding: 5px 5px 5px 15px;
	display: block; /* this gives the link block properties causing it to fill the whole LI containing it. This causes the entire area to react to a mouse click. */
	text-decoration: none;
	background-color: #000;
	color: #DDF;
}
ul.nav a:hover, ul.nav a:active, ul.nav a:focus { /* this changes the background and text color for both mouse and keyboard navigators */
	background-color: #000;
	color: #FFF;
}
/* ~~ The footer ~~ */
.footer {
	padding: 0px;
	background-color: #000;
	color: #FFF;
	position: relative;/* this gives IE6 hasLayout to properly clear */
	clear: both; /* this clear property forces the .container to understand where the columns end and contain them */
}
/* ~~ miscellaneous float/clear classes ~~ */
.fltrt {  /* this class can be used to float an element right in your page. The floated element must precede the element it should be next to on the page. */
	float: right;
	margin-left: 8px;
}
.fltlft { /* this class can be used to float an element left in your page. The floated element must precede the element it should be next to on the page. */
	float: left;
	margin-right: 8px;
}
.clearfloat { /* this class can be placed on a <br /> or empty div as the final element following the last floated div (within the #container) if the #footer is removed or taken out of the #container */
	clear: both;
	height: 0;
	font-size: 1px;
	line-height: 0px;
}
.footer p {
	text-align: center;
}
div.content ul li {
	border-right: 0px;
}
-->
</style>
</head>

<body>
<div class="container">
  <div class="header">
    <table width="100%" border="0" cellpadding="0" cellspacing="0">
      <tr height="90">
        <td height="90" width="20%" valign="middle" align="left"><img src="" name="Zedom8or" alt="Zedom8or" width="100%" height="90" style="background-color: #000; color: #FFF; display: block;" /></td>
        <td height="90" valign="middle" align="center" width="8">&nbsp;</td>
        <td height="90" valign="middle" align="right" style="padding-right: 8px; border-bottom: 1px #DDD solid;">Status</td>
      </tr>
    </table>
  </div>
  <div class="sidebar1">
    <ul class="nav">
      <li><a href="index.php">Status</a></li>
    </ul>
  </div>
  <div class="content">
    <h1>Heading 1</h1>
    <h2>Heading 2</h2>
    <h3>Heading 3</h3>
    <p>Paragraph</p>
    <p><a href="http://www.quinnebert.net/">Hyperlink</a></p>
    <ul>
      <li>Unordered List Item</li>
      <li>Unordered List Item</li>
      <li>Unordered List Item</li>
    </ul>
  </div>
  <div class="footer">
    <p>Zedom8or&nbsp;|&nbsp;The&nbsp;Open&nbsp;Source&nbsp;Home&nbsp;Theatre&nbsp;Automation&nbsp;Solution <br />
      by&nbsp;Quinn&nbsp;Ebert&nbsp;|&nbsp;<a href="http://www.QuinnEbert.net">http://www.QuinnEbert.net</a> <br />
      <em style="border-top: 3px solid #DDD; display: block; margin-top: 8px; padding-top: 4px;">This product is in no way endorsed, condoned,<br />or supported by Pioneer Corporation of America, its<br />parent or related companies, or by Jon Rhees of<br />the USB-UIRT project.</em> </p>
  </div>
</div>
</body>
</html>
