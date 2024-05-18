#include <gtk/gtk.h>

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "My Blog");

    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    GtkWidget *label = gtk_label_new("Hello, Blog World!");
    gtk_container_add(GTK_CONTAINER(window), label);
    
    gtk_widget_show_all(window);

    gtk_main();

    return 0;
}