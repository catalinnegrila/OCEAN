import Foundation

class EpsiMatParser
{
    init(model: Model)
    {
        let mat = MatData(fileUrl: model.fileUrl!)

        model.epsi_blocks = [EpsiModelData()]
        let epsi = model.epsi_blocks.first!
        epsi.time_s = transpose(mat: mat.getMatrixDouble2(name: "epsi.time_s"))
        epsi.t1_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.t1_volt"))
        epsi.t2_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.t2_volt"))
        epsi.s1_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.s1_volt"))
        epsi.s2_volt = transpose(mat: mat.getMatrixDouble2(name: "epsi.s2_volt"))
        epsi.a1_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a1_g"))
        epsi.a2_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a2_g"))
        epsi.a3_g = transpose(mat: mat.getMatrixDouble2(name: "epsi.a3_g"))

        model.ctd_blocks = [CtdModelData()]
        let ctd = model.ctd_blocks.first!
        ctd.time_s = transpose(mat: mat.getMatrixDouble2(name: "ctd.time_s"))
        ctd.P = transpose(mat: mat.getMatrixDouble2(name: "ctd.P"))
        ctd.T = transpose(mat: mat.getMatrixDouble2(name: "ctd.T"))
        ctd.S = transpose(mat: mat.getMatrixDouble2(name: "ctd.S"))
        ctd.z = transpose(mat: mat.getMatrixDouble2(name: "ctd.z"))
        model.isUpdated = true
    }

    func transpose(mat: [[Double]]) -> [Double]
    {
        assert(mat[0].count == 1)
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            result[i] = mat[i][0]
        }
        return result
    }
}

