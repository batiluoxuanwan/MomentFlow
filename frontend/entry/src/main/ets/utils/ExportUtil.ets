import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit'; // 💡 导入文件 URI 转换工具

export class ExportUtil {
  static async downloadAndSharePdf(diaryId: number, context: common.UIAbilityContext): Promise<void> {
    const httpRequest: http.HttpRequest = http.createHttp();

    try {
      // 1. 获取 PDF 数据
      const res: http.HttpResponse = await httpRequest.request(
        `http://10.0.2.2:8080/api/diary/export/pdf/${diaryId}`,
        {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        }
      );

      if (res.result instanceof ArrayBuffer) {
        const pdfData: ArrayBuffer = res.result;

        // 2. 在沙箱生成文件（文件名写死，解决手动输入烦恼）
        const fileName = `Diary_Export_${diaryId}.pdf`;
        const filePath = `${context.filesDir}/${fileName}`; // 使用 filesDir 更稳妥

        // 3. 写入文件
        const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, pdfData);
        fs.closeSync(file);

        // 4. 💡 将路径转换为系统分享可识别的 URI
        const uriString = fileUri.getUriFromPath(filePath);

        // 5. 构造分享数据
        const data: systemShare.SharedData = new systemShare.SharedData({
          utd: 'com.adobe.pdf',
          uri: uriString,
          title: fileName
        });

        // 6. 💡 修正调用：去掉不支持的 preview 属性
        const controller: systemShare.ShareController = new systemShare.ShareController(data);

        // 如果这里还报错，尝试直接调用 controller.show(context) 而不传第二个参数
        controller.show(context, {
          // 这里保持空对象，或根据 DevEco 提示添加可用属性（如 selectionMode）
        });

        promptAction.showToast({ message: '导出成功，请选择分享/保存方式' });
      }
    } catch (err) {
      const error: Error = err as Error;
      promptAction.showToast({ message: '操作失败: ' + error.message });
      console.error('Share Error:', error.message);
    } finally {
      httpRequest.destroy();
    }
  }
}