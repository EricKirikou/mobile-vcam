using MobileVirtualCamera.Desktop.ViewModels;
using System.Windows;
using System.Windows.Controls;

namespace MobileVirtualCamera.Desktop.Views.Pages;

public partial class LoginPage : UserControl
{
    public LoginPage()
    {
        InitializeComponent();
    }

    private void UserPasswordBox_PasswordChanged(object sender, RoutedEventArgs e)
    {
        if (DataContext is LoginViewModel vm && sender is PasswordBox pb)
        {
            vm.Password = pb.Password;
        }
    }
}

