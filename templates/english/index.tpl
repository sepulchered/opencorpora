{* Smarty *}
{include file='commonhtmlheader.tpl'}
<body>
<div id='main'>
{include file='english/header.tpl'}
<div id='content'>
<h1>Open Corpora</h1>
<p>Hi!</p>
<p>This is the website of the OpenCorpora project. Our goal is to create an annotated (morphologically, syntactically and semantically) corpus of texts in Russian which will be fully accessible to researchers, the annotation being crowd-sourced.</p>
<p>We started in 2009, the development is under way. You may follow our progress <a href="http://opencorpora.googlecode.com">here</a> (yes, the project is opensource).</p>
<h2>Как я могу помочь?</h2>
<p>Если вы:</p>
<ul>
<li>интересуетесь компьютерной лингвистикой и хотите поучаствовать в настоящем проекте;</li>
<li>хотя бы немного умеете программировать;</li>
<li>не знаете ничего о лингвистике и программировании, но вам просто интересно</li>
</ul>
<p>&ndash; пишите нам на <b>{mailto address=opencorpora@opencorpora.org encode=javascript}</b></p>
{* Admin options *}
{if $is_admin == 1}
    <a href='{$web_prefix}/books.php'>Редактор источников</a><br/>
    <a href='{$web_prefix}/dict.php'>Редактор словаря</a><br/><br/>
    <a href='{$web_prefix}/add.php'>Добавить текст</a><br/>
    <br/>
{/if}
<a href='?rand'>Случайное предложение</a><br/>
</div>
<div id='rightcol'>
{include file='english/right.tpl'}
</div>
<div id='fake'></div>
</div>
{include file='footer.tpl'}
</body>
{include file='commonhtmlfooter.tpl'}
