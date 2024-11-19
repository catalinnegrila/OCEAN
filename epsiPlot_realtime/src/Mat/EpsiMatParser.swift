import Foundation

class EpsiMatParser
{
    init(model: Model)
    {
        let mat = MatParser(fileUrl: model.fileUrl!)

        model.epsi_blocks = [EpsiModelData()]
        let epsi = model.epsi_blocks.first!
        epsi.time_s = mat.getMatrixNumeric1(name: "epsi.time_s")
        epsi.t1_volt = mat.getMatrixNumeric1(name: "epsi.t1_volt")
        epsi.t2_volt = mat.getMatrixNumeric1(name: "epsi.t2_volt")
        epsi.s1_volt = mat.getMatrixNumeric1(name: "epsi.s1_volt")
        epsi.s2_volt =  mat.getMatrixNumeric1(name: "epsi.s2_volt")
        epsi.a1_g = mat.getMatrixNumeric1(name: "epsi.a1_g")
        epsi.a2_g = mat.getMatrixNumeric1(name: "epsi.a2_g")
        epsi.a3_g = mat.getMatrixNumeric1(name: "epsi.a3_g")

        model.ctd_blocks = [CtdModelData()]
        let ctd = model.ctd_blocks.first!
        ctd.time_s = mat.getMatrixNumeric1(name: "ctd.time_s")
        ctd.P = mat.getMatrixNumeric1(name: "ctd.P")
        ctd.T = mat.getMatrixNumeric1(name: "ctd.T")
        ctd.S = mat.getMatrixNumeric1(name: "ctd.S")
        ctd.z = mat.getMatrixNumeric1(name: "ctd.z")
        model.isUpdated = true
    }
}

