import Foundation

class EpsiDataModelMat: EpsiDataModel
{
    override func openFile(_ fileUrl: URL)
    {
        super.openFile(fileUrl)
        let mat = MatData(fileUrl: fileUrl)

        epsi.time_s = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.time_s"))
        epsi.t1_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.t1_volt"))
        epsi.t2_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.t2_volt"))
        epsi.s1_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.s1_volt"))
        epsi.s2_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.s2_volt"))
        epsi.a1_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a1_g"))
        epsi.a2_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a2_g"))
        epsi.a3_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a3_g"))

        ctd.time_s = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.time_s"))
        ctd.P = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.P"))
        ctd.T = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.T"))
        ctd.S = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.S"))
        ctd.z = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.z"))
        ctd.dzdt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.dzdt"))

        update()
        printValues()

        time_window_start = min(epsi.time_s.first!, ctd.time_s.first!)
        time_window_length = max(epsi.time_s.last!, ctd.time_s.last!) - time_window_start
    }
}

