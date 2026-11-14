program Tarefas.API.Tests;

{$STRONGLINKTYPES ON}

uses
  Vcl.Forms,
  DUnitX.Loggers.GUI.VCL {GUIVCLTestRunner},
  DUnitX.TestFramework,
  Shared.Exceptions in '..\src\Shared\Shared.Exceptions.pas',
  Shared.Result in '..\src\Shared\Shared.Result.pas',
  Domain.ValueObjects in '..\src\Domain\Domain.ValueObjects.pas',
  Domain.Entities in '..\src\Domain\Domain.Entities.pas',
  Domain.Interfaces in '..\src\Domain\Domain.Interfaces.pas',
  Application.DTOs in '..\src\Application\Application.DTOs.pas',
  Application.Validators in '..\src\Application\Application.Validators.pas',
  Application.Services in '..\src\Application\Application.Services.pas',
  Shared.Result.Tests in 'src\Shared\Shared.Result.Tests.pas',
  Domain.Interfaces.Fakes in 'src\Domain\Domain.Interfaces.Fakes.pas',
  Domain.ValueObjects.Tests in 'src\Domain\Domain.ValueObjects.Tests.pas',
  Domain.Entities.Tests in 'src\Domain\Domain.Entities.Tests.pas',
  Application.Validators.Tests in 'src\Application\Application.Validators.Tests.pas',
  Application.Services.Tests in 'src\Application\Application.Services.Tests.pas',
  API.Controllers.Tests in 'src\API\API.Controllers.Tests.pas';

begin
  ReportMemoryLeaksOnShutdown := True;
  Vcl.Forms.Application.Initialize;
  Vcl.Forms.Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Vcl.Forms.Application.Run;
end.
