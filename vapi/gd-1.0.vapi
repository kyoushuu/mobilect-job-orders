/* gd-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Gd", gir_namespace = "Gd", gir_version = "1.0", lower_case_cprefix = "gd_")]
namespace Gd {
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_bar_get_type ()")]
	public class HeaderBar : Gtk.Container, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public HeaderBar ();
		public unowned Gtk.Widget get_custom_title ();
		public unowned string get_subtitle ();
		public unowned string get_title ();
		public void pack_end (Gtk.Widget child);
		public void pack_start (Gtk.Widget child);
		public void set_custom_title (Gtk.Widget? title_widget);
		public void set_subtitle (string? subtitle);
		public void set_title (string? title);
		public Gtk.Widget custom_title { get; set construct; }
		[NoAccessorMethod]
		public int hpadding { get; set; }
		[NoAccessorMethod]
		public int spacing { get; set; }
		public string subtitle { get; set; }
		public string title { get; set; }
		[NoAccessorMethod]
		public int vpadding { get; set; }
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_menu_button_get_type ()")]
	public class HeaderMenuButton : Gtk.MenuButton, Atk.Implementor, Gd.HeaderButton, Gtk.Actionable, Gtk.Activatable, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public HeaderMenuButton ();
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_radio_button_get_type ()")]
	public class HeaderRadioButton : Gtk.RadioButton, Atk.Implementor, Gd.HeaderButton, Gtk.Actionable, Gtk.Activatable, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public HeaderRadioButton ();
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_simple_button_get_type ()")]
	public class HeaderSimpleButton : Gtk.Button, Atk.Implementor, Gd.HeaderButton, Gtk.Actionable, Gtk.Activatable, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public HeaderSimpleButton ();
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_toggle_button_get_type ()")]
	public class HeaderToggleButton : Gtk.ToggleButton, Atk.Implementor, Gd.HeaderButton, Gtk.Actionable, Gtk.Activatable, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public HeaderToggleButton ();
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_notification_get_type ()")]
	public class Notification : Gtk.Bin, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Notification ();
		public void dismiss ();
		public void set_show_close_button (bool show_close_button);
		public void set_timeout (int timeout_sec);
		[NoAccessorMethod]
		public bool show_close_button { get; set construct; }
		[NoAccessorMethod]
		public int timeout { get; set construct; }
		public virtual signal void dismissed ();
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_revealer_get_type ()")]
	public class Revealer : Gtk.Bin, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Revealer ();
		public bool get_child_revealed ();
		public Gtk.Orientation get_orientation ();
		public bool get_reveal_child ();
		public int get_transition_duration ();
		public void set_orientation (Gtk.Orientation value);
		public void set_reveal_child (bool setting);
		public void set_transition_duration (int duration_msec);
		public bool child_revealed { get; }
		public Gtk.Orientation orientation { get; set construct; }
		public bool reveal_child { get; set construct; }
		public int transition_duration { get; set construct; }
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_stack_get_type ()")]
	public class Stack : Gtk.Container, Atk.Implementor, Gtk.Buildable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public Stack ();
		public void add_named (Gtk.Widget child, string name);
		public void add_titled (Gtk.Widget child, string name, string title);
		public bool get_homogeneous ();
		public int get_transition_duration ();
		public Gd.StackTransitionType get_transition_type ();
		public unowned Gtk.Widget get_visible_child ();
		public unowned string get_visible_child_name ();
		public void set_homogeneous (bool homogeneous);
		public void set_transition_duration (int transition_duration);
		public void set_transition_type (Gd.StackTransitionType type);
		public void set_visible_child (Gtk.Widget child);
		public void set_visible_child_name (string name);
		public bool homogeneous { get; set construct; }
		public int transition_duration { get; set construct; }
		public int transition_type { get; set construct; }
		public Gtk.Widget visible_child { get; set; }
		public string visible_child_name { get; set; }
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_stack_switcher_get_type ()")]
	public class StackSwitcher : Gtk.Box, Atk.Implementor, Gtk.Buildable, Gtk.Orientable {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public StackSwitcher ();
		public unowned Gd.Stack get_stack ();
		public void set_stack (Gd.Stack? stack);
		public Gd.Stack stack { get; set construct; }
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_tagged_entry_get_type ()")]
	public class TaggedEntry : Gtk.SearchEntry, Atk.Implementor, Gtk.Buildable, Gtk.CellEditable, Gtk.Editable {
		[CCode (has_construct_function = false)]
		public TaggedEntry ();
		public bool add_tag (Gd.TaggedEntryTag tag);
		public bool get_tag_button_visible ();
		public bool insert_tag (Gd.TaggedEntryTag tag, int position);
		public bool remove_tag (Gd.TaggedEntryTag tag);
		public void set_tag_button_visible (bool visible);
		[NoAccessorMethod]
		public bool tag_close_visible { set; }
		public signal void tag_button_clicked (Gd.TaggedEntryTag object);
		public signal void tag_clicked (Gd.TaggedEntryTag object);
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_tagged_entry_tag_get_type ()")]
	public class TaggedEntryTag : GLib.Object {
		[CCode (has_construct_function = false)]
		public TaggedEntryTag (string label);
		public bool get_has_close_button ();
		public unowned string get_label ();
		public unowned string get_style ();
		public void set_has_close_button (bool has_close_button);
		public void set_label (string label);
		public void set_style (string style);
		public bool has_close_button { get; set construct; }
		public string label { get; set construct; }
		public string style { get; set construct; }
	}
	[CCode (cheader_filename = "libgd/gd.h", type_id = "gd_header_button_get_type ()")]
	public interface HeaderButton : Gtk.Button {
		public string get_label ();
		public string get_symbolic_icon_name ();
		public bool get_use_markup ();
		public void set_label (string? label);
		public void set_symbolic_icon_name (string? symbolic_icon_name);
		public void set_use_markup (bool use_markup);
		[NoAccessorMethod]
		public abstract string label { owned get; set; }
		[NoAccessorMethod]
		public abstract string symbolic_icon_name { owned get; set; }
		[NoAccessorMethod]
		public abstract bool use_markup { get; set; }
	}
	[CCode (cheader_filename = "libgd/gd.h", cprefix = "GD_STACK_TRANSITION_TYPE_", has_type_id = false)]
	public enum StackTransitionType {
		NONE,
		CROSSFADE,
		SLIDE_RIGHT,
		SLIDE_LEFT
	}
	[CCode (cheader_filename = "libgd/gd.h")]
	public static void ensure_types ();
}
