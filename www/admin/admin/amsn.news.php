<?php

if (!defined('CPanel') || !isset($_SESSION['user'], $_SESSION['level'], $_GET['action'])) {
    require_once 'lib.misc.php';
    noperms();
    exit;
}

function form($title = '', $text = '', $idn = 0) {
?>
<br />
Convert your text to valid xhtml at: <a href="http://textism.com/tools/textile/index.html">http://textism.com/tools/textile/index.html</a> before posting.<br /><br /> <br />

Create a link to the forums at: <a href="http://www.amsn-project.net/forums">http://www.amsn-project.net/forums/</a> so that we may receive comments on each news item.<br /><br /> <br />
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="title">Title:</label><input type="text" maxlength="150" name="title" id="title"<?php echo !empty($title) ? " value=\"".trans($title)."\"" : '' ?> /><br />
    <label for="text">Text:</label><textarea rows="20" cols="50" name="text" id="text"><?php echo !empty($text) ? trans($text) : '' ?></textarea><br />
<?php
    if ($idn != 0) {
?>
    <input type="hidden" name="id" value="<?php echo $idn ?>" />
<?php
}
?>
    <input type="submit" />
</form>
<?php
}

if ($_GET['action'] == 'add') {
    if (isset($_POST['title'], $_POST['text'])) {
        $_POST = clean4sql($_POST);
        if (mysql_query("INSERT INTO `amsn_news` (author, time) VALUES ('" . (int)$_SESSION['id'] . "', UNIX_TIMESTAMP())")) {
	  $title=$_POST['title'];
	  $text=$_POST['text'];
	  $id=mysql_insert_id();
	  $query="UPDATE amsn_news SET title='news_{$id}_title',text='news_{$id}_text' WHERE id='$id'";
	  mysql_query($query) or die(mysql_error());
	  $query="INSERT INTO amsn_langs (lang_key,lang_text) VALUES ('news_{$id}_title','$title')";
	  mysql_query($query) or die(mysql_error());
	  $query="INSERT INTO amsn_langs (lang_key,lang_text) VALUES ('news_{$id}_text','$text')";
	  mysql_query($query) or die(mysql_error());
	  echo "<p>Post successfully added to the database</p>\n";
	  return;
        } else {
            echo "<p>An error ocurred while trying to add the post to the database</p>\n";
            form(htmlentities($_POST['title']), htmlentities($_POST['text']));
            return;
        }
    }

    form();
} else if ($_GET['action'] == 'remove' || $_GET['action'] == 'edit') {
    if (!mysql_num_rows(($q = @mysql_query("SELECT * FROM `amsn_news` ORDER BY title DESC, id ASC")))) {
        echo "<p>There are no posts at this moment, you can <a href=\"index.php?load=news&amp;action=add\">create one</a></p>\n";
        return;
    }

    if (isset($_POST['id']) && ereg('^[1-9][0-9]*$', ($_POST['id'] = (int)$_POST['id']))) {
        if ($_GET['action'] == 'edit') {
            if (!@mysql_num_rows(($q = mysql_query("SELECT title, text FROM `amsn_news` WHERE id = '{$_POST['id']}' LIMIT 1")))) {
                echo "<p>The selected post don't exists</p>\n";
                return;
            }

            if (isset($_POST['title'], $_POST['text']) && !empty($_POST['title']) && !empty($_POST['text'])) {
                if (@mysql_query("UPDATE `amsn_langs` SET lang_text = '{$_POST['title']}' WHERE lang_key='news_{$_POST['id']}_title' LIMIT 1") && @mysql_query("UPDATE `amsn_langs` SET lang_text = '{$_POST['text']}' WHERE lang_key='news_{$_POST['id']}_text' LIMIT 1"))
                    echo "<p>Post successfully updated</p>\n";
                else
                    echo "<p>There was an error while trying to insert the new post</p>\n";

                return;
            }

            $row = mysql_fetch_assoc($q);
            form(htmlentities(stripslashes($row['title'])), htmlentities(stripslashes($row['text'])), $_POST['id']);
            return;
        } else if ($_GET['action'] == 'remove') {
            if (mysql_query("DELETE FROM `amsn_news` WHERE id = '{$_POST['id']}' LIMIT 1") && mysql_query("DELETE FROM `amsn_langs` WHERE lang_key LIKE 'news_{$_POST['id']}%'")) {
                echo "<p>Post successfully deleted</p>\n";
                return;
            } else {
                echo "<p>There was an error where trying to remove the database registry</p>\n";
            }        
        }
    }

?>
<form action="<?php echo htmlentities($_SERVER['REQUEST_URI']) ?>" method="post" id="form">
    <label for="id">Title:</label><select name="id" id="id">
<?php
while ($row = mysql_fetch_assoc($q)) {
?>
        <option value="<?php echo $row['id'] ?>"><?php echo htmlentities(stripslashes(trans($row['title']))) ?></option>
<?php
}
?>
</select>
<input type="submit" />
</form>
<?php
} else {
    echo "<p>You have requested an unknow action</p>\n";
    return;
}

?>
